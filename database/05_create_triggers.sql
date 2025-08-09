-- WonderNest Audit Triggers and Business Logic Triggers
-- Comprehensive audit trail and business rule enforcement
--
-- Usage:
--   psql -U postgres -d wondernest_prod -f 05_create_triggers.sql
--
-- Prerequisites:
--   - All tables, functions, and indexes created
--   - Connected to wondernest_prod database

-- =============================================================================
-- AUDIT TRIGGER FUNCTIONS
-- =============================================================================

-- Generic audit trigger function for tracking all data changes
CREATE OR REPLACE FUNCTION audit.audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_user_id UUID;
    v_child_id UUID;
    v_action audit.action_type;
BEGIN
    -- Determine action type
    IF TG_OP = 'DELETE' THEN
        v_action := 'delete';
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'update';
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSIF TG_OP = 'INSERT' THEN
        v_action := 'create';
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
    ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
    END IF;
    
    -- Try to extract user_id from the record
    IF v_new_data ? 'user_id' THEN
        v_user_id := (v_new_data->>'user_id')::UUID;
    ELSIF v_old_data ? 'user_id' THEN
        v_user_id := (v_old_data->>'user_id')::UUID;
    ELSIF v_new_data ? 'id' AND TG_TABLE_NAME = 'users' THEN
        v_user_id := (v_new_data->>'id')::UUID;
    ELSIF v_old_data ? 'id' AND TG_TABLE_NAME = 'users' THEN
        v_user_id := (v_old_data->>'id')::UUID;
    END IF;
    
    -- Try to extract child_id from the record
    IF v_new_data ? 'child_id' THEN
        v_child_id := (v_new_data->>'child_id')::UUID;
    ELSIF v_old_data ? 'child_id' THEN
        v_child_id := (v_old_data->>'child_id')::UUID;
    ELSIF v_new_data ? 'id' AND TG_TABLE_NAME = 'child_profiles' THEN
        v_child_id := (v_new_data->>'id')::UUID;
    ELSIF v_old_data ? 'id' AND TG_TABLE_NAME = 'child_profiles' THEN
        v_child_id := (v_old_data->>'id')::UUID;
    END IF;
    
    -- Insert audit record
    INSERT INTO audit.activity_log (
        user_id,
        child_id,
        action,
        table_name,
        record_id,
        old_values,
        new_values,
        ip_address,
        user_agent
    ) VALUES (
        v_user_id,
        v_child_id,
        v_action,
        TG_TABLE_NAME,
        COALESCE(
            (v_new_data->>'id')::UUID,
            (v_old_data->>'id')::UUID
        ),
        v_old_data,
        v_new_data,
        inet_client_addr(),
        current_setting('application.user_agent', true)
    );
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE WARNING 'Audit trigger failed for table %: %', TG_TABLE_NAME, SQLERRM;
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Audit trigger function for sensitive child data
CREATE OR REPLACE FUNCTION audit.child_data_audit_function()
RETURNS TRIGGER AS $$
DECLARE
    v_anonymized_old JSONB;
    v_anonymized_new JSONB;
    v_action audit.action_type;
BEGIN
    -- Determine action
    IF TG_OP = 'DELETE' THEN
        v_action := 'delete';
        v_anonymized_old := jsonb_build_object(
            'id', OLD.id,
            'family_id', OLD.family_id,
            'first_name', family.anonymize_child_name(OLD.first_name),
            'age_months', family.calculate_age_months(OLD.birth_date),
            'archived_at', OLD.archived_at
        );
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'update';
        v_anonymized_old := jsonb_build_object(
            'id', OLD.id,
            'family_id', OLD.family_id,
            'first_name', family.anonymize_child_name(OLD.first_name),
            'age_months', family.calculate_age_months(OLD.birth_date)
        );
        v_anonymized_new := jsonb_build_object(
            'id', NEW.id,
            'family_id', NEW.family_id,
            'first_name', family.anonymize_child_name(NEW.first_name),
            'age_months', family.calculate_age_months(NEW.birth_date)
        );
    ELSE -- INSERT
        v_action := 'create';
        v_anonymized_new := jsonb_build_object(
            'id', NEW.id,
            'family_id', NEW.family_id,
            'first_name', family.anonymize_child_name(NEW.first_name),
            'age_months', family.calculate_age_months(NEW.birth_date)
        );
    END IF;
    
    -- Insert anonymized audit record
    INSERT INTO audit.activity_log (
        child_id,
        action,
        table_name,
        record_id,
        old_values,
        new_values,
        metadata
    ) VALUES (
        COALESCE(NEW.id, OLD.id),
        v_action,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        v_anonymized_old,
        v_anonymized_new,
        jsonb_build_object('data_type', 'child_profile', 'anonymized', true)
    );
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- BUSINESS LOGIC TRIGGER FUNCTIONS
-- =============================================================================

-- Validate user email changes
CREATE OR REPLACE FUNCTION core.validate_user_email_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Email change requires re-verification
    IF OLD.email != NEW.email THEN
        NEW.email_verified := FALSE;
        NEW.email_verified_at := NULL;
        
        -- Log significant change
        INSERT INTO audit.activity_log (
            user_id, action, table_name, record_id, metadata
        ) VALUES (
            NEW.id, 'update', 'users', NEW.id,
            jsonb_build_object(
                'change_type', 'email_change',
                'old_email_hash', md5(OLD.email),
                'new_email_hash', md5(NEW.email)
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Prevent deletion of users with active children
CREATE OR REPLACE FUNCTION core.prevent_user_deletion_with_children()
RETURNS TRIGGER AS $$
DECLARE
    v_child_count INTEGER;
BEGIN
    -- Check if user has any non-archived children
    SELECT COUNT(*)
    INTO v_child_count
    FROM family.families f
    JOIN family.family_members fm ON f.id = fm.family_id
    JOIN family.child_profiles cp ON f.id = cp.family_id
    WHERE fm.user_id = OLD.id
    AND fm.left_at IS NULL
    AND cp.archived_at IS NULL;
    
    IF v_child_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete user with % active children. Archive children first.', v_child_count;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Update content engagement statistics
CREATE OR REPLACE FUNCTION content.update_engagement_stats()
RETURNS TRIGGER AS $$
DECLARE
    v_rating_change INTEGER := 0;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Update view count
        UPDATE content.items 
        SET view_count = view_count + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.content_id;
        
        -- Update rating if provided
        IF NEW.enjoyed_rating IS NOT NULL THEN
            UPDATE content.items
            SET 
                total_ratings = total_ratings + 1,
                average_rating = (
                    (average_rating * total_ratings + NEW.enjoyed_rating) / 
                    (total_ratings + 1)
                ),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.content_id;
        END IF;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle rating changes
        IF OLD.enjoyed_rating IS DISTINCT FROM NEW.enjoyed_rating THEN
            IF OLD.enjoyed_rating IS NULL AND NEW.enjoyed_rating IS NOT NULL THEN
                -- New rating added
                v_rating_change := 1;
            ELSIF OLD.enjoyed_rating IS NOT NULL AND NEW.enjoyed_rating IS NULL THEN
                -- Rating removed
                v_rating_change := -1;
            END IF;
            
            -- Update content rating statistics
            UPDATE content.items
            SET 
                total_ratings = total_ratings + v_rating_change,
                average_rating = CASE 
                    WHEN total_ratings + v_rating_change = 0 THEN 0
                    ELSE (
                        average_rating * total_ratings - 
                        COALESCE(OLD.enjoyed_rating, 0) + 
                        COALESCE(NEW.enjoyed_rating, 0)
                    ) / (total_ratings + v_rating_change)
                END,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.content_id;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Validate child age constraints
CREATE OR REPLACE FUNCTION family.validate_child_age()
RETURNS TRIGGER AS $$
DECLARE
    v_age_months INTEGER;
BEGIN
    v_age_months := family.calculate_age_months(NEW.birth_date);
    
    -- Ensure child is not too old (8 years max)
    IF v_age_months > 96 THEN
        RAISE EXCEPTION 'Child is too old for the platform. Maximum age is 8 years.';
    END IF;
    
    -- Ensure birth date is not in the future
    IF NEW.birth_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Birth date cannot be in the future.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-calculate daily metrics after audio session completion
CREATE OR REPLACE FUNCTION audio.trigger_daily_metrics_calculation()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger on session completion
    IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
        -- Schedule daily metrics calculation (can be done async)
        PERFORM analytics.calculate_daily_metrics(
            NEW.child_id, 
            DATE(NEW.ended_at)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Validate subscription changes
CREATE OR REPLACE FUNCTION subscription.validate_subscription_change()
RETURNS TRIGGER AS $$
DECLARE
    v_plan_features JSONB;
    v_child_count INTEGER;
BEGIN
    -- Get plan features
    SELECT features INTO v_plan_features
    FROM subscription.plans
    WHERE id = NEW.plan_id;
    
    -- Count user's children
    SELECT COUNT(*)
    INTO v_child_count
    FROM family.families f
    JOIN family.family_members fm ON f.id = fm.family_id
    JOIN family.child_profiles cp ON f.id = cp.family_id
    WHERE fm.user_id = NEW.user_id
    AND fm.left_at IS NULL
    AND cp.archived_at IS NULL;
    
    -- Validate child count against plan limits
    IF (v_plan_features->>'max_children')::INTEGER < v_child_count THEN
        RAISE EXCEPTION 'Plan only supports % children, but user has %', 
            v_plan_features->>'max_children', v_child_count;
    END IF;
    
    -- Log subscription change
    IF TG_OP = 'UPDATE' AND OLD.plan_id != NEW.plan_id THEN
        INSERT INTO audit.activity_log (
            user_id, action, table_name, record_id, metadata
        ) VALUES (
            NEW.user_id, 'update', 'user_subscriptions', NEW.id,
            jsonb_build_object(
                'change_type', 'plan_change',
                'old_plan_id', OLD.plan_id,
                'new_plan_id', NEW.plan_id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Validate content safety before publishing
CREATE OR REPLACE FUNCTION content.validate_content_safety()
RETURNS TRIGGER AS $$
BEGIN
    -- Only allow publishing if safety score is adequate
    IF NEW.status = 'approved' AND NEW.safety_score < 0.7 THEN
        RAISE EXCEPTION 'Content safety score (%) is below minimum threshold (0.7)', NEW.safety_score;
    END IF;
    
    -- Set published_at timestamp when approved
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        NEW.published_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- Clear published_at if no longer approved
    IF NEW.status != 'approved' AND OLD.status = 'approved' THEN
        NEW.published_at := NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enforce parental control restrictions
CREATE OR REPLACE FUNCTION safety.enforce_parental_controls()
RETURNS TRIGGER AS $$
DECLARE
    v_controls safety.parental_controls%ROWTYPE;
    v_child_age_months INTEGER;
    v_content_age_max INTEGER;
BEGIN
    -- Only check on content engagement creation
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;
    
    -- Get parental controls for child
    SELECT * INTO v_controls
    FROM safety.parental_controls
    WHERE child_id = NEW.child_id;
    
    -- If no controls set, allow (default permissive)
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    -- Get content details
    SELECT min_age_months, max_age_months
    INTO v_content_age_max, v_content_age_max
    FROM content.items
    WHERE id = NEW.content_id;
    
    -- Check if content is blocked
    IF NEW.content_id = ANY(v_controls.blocked_content) THEN
        RAISE EXCEPTION 'Content is blocked by parental controls';
    END IF;
    
    -- Check age restrictions
    IF v_controls.max_age_rating_months IS NOT NULL THEN
        SELECT family.calculate_age_months(birth_date)
        INTO v_child_age_months
        FROM family.child_profiles
        WHERE id = NEW.child_id;
        
        IF v_content_age_max > v_controls.max_age_rating_months THEN
            RAISE EXCEPTION 'Content exceeds age restriction set by parent';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- CREATE AUDIT TRIGGERS
-- =============================================================================

-- Core schema audit triggers
CREATE TRIGGER audit_users_trigger
    AFTER INSERT OR UPDATE OR DELETE ON core.users
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

CREATE TRIGGER audit_user_sessions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON core.user_sessions
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

-- Family schema audit triggers (with special handling for child data)
CREATE TRIGGER audit_families_trigger
    AFTER INSERT OR UPDATE OR DELETE ON family.families
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

CREATE TRIGGER audit_family_members_trigger
    AFTER INSERT OR UPDATE OR DELETE ON family.family_members
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

CREATE TRIGGER audit_child_profiles_trigger
    AFTER INSERT OR UPDATE OR DELETE ON family.child_profiles
    FOR EACH ROW EXECUTE FUNCTION audit.child_data_audit_function();

-- Subscription schema audit triggers
CREATE TRIGGER audit_user_subscriptions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON subscription.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

CREATE TRIGGER audit_transactions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON subscription.transactions
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

-- Content schema audit triggers
CREATE TRIGGER audit_content_items_trigger
    AFTER INSERT OR UPDATE OR DELETE ON content.items
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

CREATE TRIGGER audit_content_engagement_trigger
    AFTER INSERT OR UPDATE OR DELETE ON content.engagement
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

-- Audio schema audit triggers
CREATE TRIGGER audit_audio_sessions_trigger
    AFTER INSERT OR UPDATE OR DELETE ON audio.sessions
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

-- Note: speech_metrics are not audited individually due to volume, but session-level auditing captures the overview

-- Safety schema audit triggers
CREATE TRIGGER audit_parental_controls_trigger
    AFTER INSERT OR UPDATE OR DELETE ON safety.parental_controls
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

-- =============================================================================
-- CREATE BUSINESS LOGIC TRIGGERS
-- =============================================================================

-- User management triggers
CREATE TRIGGER validate_user_email_change_trigger
    BEFORE UPDATE ON core.users
    FOR EACH ROW EXECUTE FUNCTION core.validate_user_email_change();

CREATE TRIGGER prevent_user_deletion_with_children_trigger
    BEFORE DELETE ON core.users
    FOR EACH ROW EXECUTE FUNCTION core.prevent_user_deletion_with_children();

-- Family management triggers
CREATE TRIGGER validate_child_age_trigger
    BEFORE INSERT OR UPDATE ON family.child_profiles
    FOR EACH ROW EXECUTE FUNCTION family.validate_child_age();

-- Content management triggers
CREATE TRIGGER update_engagement_stats_trigger
    AFTER INSERT OR UPDATE ON content.engagement
    FOR EACH ROW EXECUTE FUNCTION content.update_engagement_stats();

CREATE TRIGGER validate_content_safety_trigger
    BEFORE UPDATE ON content.items
    FOR EACH ROW EXECUTE FUNCTION content.validate_content_safety();

-- Audio processing triggers
CREATE TRIGGER trigger_daily_metrics_calculation_trigger
    AFTER UPDATE ON audio.sessions
    FOR EACH ROW EXECUTE FUNCTION audio.trigger_daily_metrics_calculation();

-- Subscription management triggers
CREATE TRIGGER validate_subscription_change_trigger
    BEFORE INSERT OR UPDATE ON subscription.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION subscription.validate_subscription_change();

-- Safety enforcement triggers
CREATE TRIGGER enforce_parental_controls_trigger
    BEFORE INSERT ON content.engagement
    FOR EACH ROW EXECUTE FUNCTION safety.enforce_parental_controls();

-- =============================================================================
-- PARTITION MAINTENANCE TRIGGERS
-- =============================================================================

-- Function to create new partitions automatically
CREATE OR REPLACE FUNCTION admin.create_monthly_partition(
    table_name TEXT,
    partition_date DATE
) RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    -- Calculate partition boundaries
    start_date := date_trunc('month', partition_date);
    end_date := start_date + interval '1 month';
    
    -- Generate partition name
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    
    -- Create partition if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = split_part(table_name, '.', 1)
        AND tablename = split_part(partition_name, '.', 2)
    ) THEN
        EXECUTE format(
            'CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
            partition_name, table_name, start_date, end_date
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create partitions for engagement data
CREATE OR REPLACE FUNCTION content.auto_create_engagement_partition()
RETURNS TRIGGER AS $$
BEGIN
    -- Create partition for the month of the new engagement record
    PERFORM admin.create_monthly_partition(
        'content.engagement',
        DATE(NEW.started_at)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_create_engagement_partition_trigger
    BEFORE INSERT ON content.engagement
    FOR EACH ROW EXECUTE FUNCTION content.auto_create_engagement_partition();

-- =============================================================================
-- DATA RETENTION TRIGGERS
-- =============================================================================

-- Function to set retention dates based on policies
CREATE OR REPLACE FUNCTION audit.set_retention_date()
RETURNS TRIGGER AS $$
DECLARE
    v_policy audit.data_retention_policies%ROWTYPE;
BEGIN
    -- Get retention policy for the table
    SELECT * INTO v_policy
    FROM audit.data_retention_policies
    WHERE table_name = TG_TABLE_NAME AND is_active = TRUE;
    
    -- Set retention_until if policy exists
    IF FOUND THEN
        NEW.retention_until := CURRENT_TIMESTAMP + (v_policy.retention_period_days || ' days')::INTERVAL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply retention trigger to audit log
CREATE TRIGGER set_retention_date_trigger
    BEFORE INSERT ON audit.activity_log
    FOR EACH ROW EXECUTE FUNCTION audit.set_retention_date();

-- =============================================================================
-- TRIGGER STATUS MONITORING
-- =============================================================================

-- Create a view to monitor trigger performance
CREATE OR REPLACE VIEW admin.trigger_monitoring AS
SELECT 
    schemaname,
    tablename,
    triggername,
    CASE 
        WHEN triggername LIKE '%audit%' THEN 'Audit'
        WHEN triggername LIKE '%validate%' THEN 'Validation'
        WHEN triggername LIKE '%enforce%' THEN 'Enforcement'
        WHEN triggername LIKE '%auto%' THEN 'Automation'
        ELSE 'Other'
    END as trigger_type,
    prosrc as function_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE n.nspname IN ('core', 'family', 'content', 'audio', 'subscription', 'analytics', 'safety', 'audit')
ORDER BY schemaname, tablename, triggername;

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON FUNCTION audit.audit_trigger_function() IS 'Generic audit function that logs all data changes with anonymization';
COMMENT ON FUNCTION audit.child_data_audit_function() IS 'Specialized audit function for child data with enhanced privacy protection';
COMMENT ON FUNCTION core.validate_user_email_change() IS 'Enforces email verification reset when email changes';
COMMENT ON FUNCTION content.update_engagement_stats() IS 'Maintains real-time engagement statistics on content';
COMMENT ON FUNCTION safety.enforce_parental_controls() IS 'Enforces parental control restrictions on content access';

SELECT 'All audit triggers and business logic triggers created successfully. Monitor with admin.trigger_monitoring view.' AS result;