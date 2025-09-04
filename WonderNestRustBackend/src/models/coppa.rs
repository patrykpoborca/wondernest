use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct COPPAConsentRequest {
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "consentType")]
    pub consent_type: String, // "parental_notification", "parental_consent", "verifiable_consent"
    pub permissions: HashMap<String, bool>, // specific permissions granted
    #[serde(rename = "verificationMethod")]
    pub verification_method: String, // "credit_card", "digital_signature", "government_id", etc.
    #[serde(rename = "verificationData")]
    pub verification_data: Option<HashMap<String, String>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct COPPAConsentResponse {
    #[serde(rename = "consentId")]
    pub consent_id: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "consentType")]
    pub consent_type: String,
    pub permissions: HashMap<String, bool>,
    #[serde(rename = "consentGranted")]
    pub consent_granted: bool,
    #[serde(rename = "expiresAt")]
    pub expires_at: Option<String>,
    #[serde(rename = "verificationStatus")]
    pub verification_status: String,
    #[serde(rename = "complianceWarnings")]
    pub compliance_warnings: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct COPPAStatusResponse {
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "consentStatus")]
    pub consent_status: String,
    #[serde(rename = "consentRequired")]
    pub consent_required: bool,
    #[serde(rename = "verificationRequired")]
    pub verification_required: bool,
    #[serde(rename = "dataCollectionAllowed")]
    pub data_collection_allowed: bool,
    pub warnings: Vec<String>,
    #[serde(rename = "nextSteps")]
    pub next_steps: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct COPPAComplianceInfo {
    #[serde(rename = "coppaCompliant")]
    pub coppa_compliant: bool,
    #[serde(rename = "implementationStatus")]
    pub implementation_status: String,
    #[serde(rename = "requiredFeatures")]
    pub required_features: Vec<String>,
    #[serde(rename = "legalRequirements")]
    pub legal_requirements: Vec<String>,
    pub warnings: Vec<String>,
}