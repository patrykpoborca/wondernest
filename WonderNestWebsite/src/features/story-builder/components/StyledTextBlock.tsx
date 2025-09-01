import React, { useState, useEffect, useMemo, useRef, useCallback } from 'react'
import { Box, Typography, Tooltip, ClickAwayListener } from '@mui/material'
import { styled } from '@mui/material/styles'
import { motion, AnimatePresence } from 'framer-motion'

import { TextBlock, TextVariant, TextBlockStyle } from '../types/story'
import { generateStyleCSS, applyAnimation, generateAnimationKeyframes } from '../utils/styleUtils'

interface StyledTextBlockProps {
  textBlock: TextBlock
  isEditing?: boolean
  isSelected?: boolean
  onSelect?: () => void
  onContentChange?: (content: string) => void
  onPositionChange?: (position: { x: number; y: number }) => void
  viewMode?: 'desktop' | 'tablet' | 'mobile'
  difficulty?: 'easy' | 'medium' | 'hard' | 'advanced'
  childAge?: number
  zoom?: number
  canvasSize?: { width: number; height: number }
}

const TextContainer = styled(Box, {
  shouldForwardProp: (prop) => prop !== 'isSelected' && prop !== 'isEditing' && prop !== 'isDragging',
})<{ isSelected?: boolean; isEditing?: boolean; isDragging?: boolean }>(({ theme, isSelected, isEditing, isDragging }) => ({
  position: 'absolute',
  cursor: isDragging ? 'grabbing' : (isEditing ? 'grab' : 'pointer'),
  userSelect: isEditing ? 'none' : 'text',
  // Only show subtle outline when selected and editing
  outline: isSelected && isEditing ? `1px solid ${theme.palette.primary.main}40` : 'none',
  outlineOffset: 2,
  transition: 'all 0.2s ease',
  
  '&:hover': {
    // Only show hover effect when editing
    outline: isEditing ? `1px dashed ${theme.palette.primary.light}40` : 'none',
  },
  
  // Add subtle resize handle only when selected and editing
  ...(isSelected && isEditing && {
    '&::after': {
      content: '""',
      position: 'absolute',
      bottom: -4,
      right: -4,
      width: 8,
      height: 8,
      backgroundColor: theme.palette.primary.main,
      borderRadius: '50%',
      cursor: 'se-resize',
      opacity: 0.5,
    },
  }),
}))

const AnimatedText = styled(motion.div)(({ theme }) => ({
  width: '100%',
  height: '100%',
  position: 'relative',
}))

export const StyledTextBlock: React.FC<StyledTextBlockProps> = ({
  textBlock,
  isEditing = false,
  isSelected = false,
  onSelect,
  onContentChange,
  onPositionChange,
  viewMode = 'desktop',
  difficulty = 'medium',
  childAge = 6,
  zoom = 1,
  canvasSize = { width: 800, height: 600 },
}) => {
  const [isDragging, setIsDragging] = useState(false)
  const [showTooltip, setShowTooltip] = useState(false)
  const [editableContent, setEditableContent] = useState('')
  const dragRef = useRef<{
    startX: number
    startY: number
    startPosX: number
    startPosY: number
  } | null>(null)

  // Convert old format to new format if needed
  const normalizedVariants = useMemo(() => {
    if (!textBlock.variants) {
      return []
    }

    // Check if variants is already an array (new format)
    if (Array.isArray(textBlock.variants)) {
      return textBlock.variants
    }

    // Convert old format (object with easy/medium/hard) to new format
    const oldVariants = textBlock.variants as any
    const variants: TextVariant[] = []

    // Create primary variant from easy or medium content
    const primaryContent = oldVariants?.easy || oldVariants?.medium || ''
    if (primaryContent) {
      variants.push({
        id: 'variant-primary',
        content: primaryContent,
        type: 'primary',
        metadata: {
          targetAge: 5,
          ageRange: [3, 7],
          vocabularyDifficulty: 'simple',
          vocabularyLevel: 3,
          readingTime: Math.ceil((primaryContent || '').split(' ').filter(Boolean).length / 200 * 60),
          wordCount: (primaryContent || '').split(' ').filter(Boolean).length,
          characterCount: (primaryContent || '').length,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })
    }

    // Create alternate variants
    if (oldVariants?.medium && oldVariants.medium !== primaryContent) {
      variants.push({
        id: 'variant-alternate-1',
        content: oldVariants.medium,
        type: 'alternate',
        metadata: {
          targetAge: 7,
          ageRange: [5, 9],
          vocabularyDifficulty: 'moderate',
          vocabularyLevel: 5,
          readingTime: Math.ceil((oldVariants.medium || '').split(' ').filter(Boolean).length / 200 * 60),
          wordCount: (oldVariants.medium || '').split(' ').filter(Boolean).length,
          characterCount: (oldVariants.medium || '').length,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })
    }

    if (oldVariants?.hard) {
      variants.push({
        id: 'variant-alternate-2',
        content: oldVariants.hard,
        type: 'alternate',
        metadata: {
          targetAge: 9,
          ageRange: [7, 12],
          vocabularyDifficulty: 'advanced',
          vocabularyLevel: 7,
          readingTime: Math.ceil((oldVariants.hard || '').split(' ').filter(Boolean).length / 200 * 60),
          wordCount: (oldVariants.hard || '').split(' ').filter(Boolean).length,
          characterCount: (oldVariants.hard || '').length,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })
    }

    return variants
  }, [textBlock.variants])

  // Select the appropriate variant
  const selectedVariant = useMemo(() => {
    if (!normalizedVariants || normalizedVariants.length === 0) {
      return null
    }

    // During editing, always show the primary variant for consistent preview
    if (isEditing) {
      const primaryVariant = normalizedVariants.find(v => v.type === 'primary')
      return primaryVariant || normalizedVariants[0]
    }

    // If there's an active variant set, use it
    if (textBlock.activeVariantId) {
      return normalizedVariants.find(v => v.id === textBlock.activeVariantId) || normalizedVariants[0]
    }

    // In view mode, select based on child age if provided
    if (childAge) {
      // Find the best matching variant based on target age
      const bestMatch = normalizedVariants.reduce((best, current) => {
        const currentAgeDiff = Math.abs(current.metadata.targetAge - childAge)
        const bestAgeDiff = best ? Math.abs(best.metadata.targetAge - childAge) : Infinity
        
        // Also check if childAge is within the age range
        const currentInRange = childAge >= current.metadata.ageRange[0] && childAge <= current.metadata.ageRange[1]
        const bestInRange = best ? (childAge >= best.metadata.ageRange[0] && childAge <= best.metadata.ageRange[1]) : false
        
        // Prefer variants where child age is in range, then closest target age
        if (currentInRange && !bestInRange) return current
        if (!currentInRange && bestInRange) return best
        if (currentAgeDiff < bestAgeDiff) return current
        
        return best
      }, null as TextVariant | null)

      if (bestMatch) return bestMatch
    }

    // Default to primary variant
    const primaryVariant = normalizedVariants.find(v => v.type === 'primary')
    return primaryVariant || normalizedVariants[0]
  }, [normalizedVariants, textBlock.activeVariantId, childAge, isEditing])

  // Generate CSS styles
  const styleCSS = useMemo(() => {
    if (!textBlock.style) return {}
    return generateStyleCSS(textBlock.style)
  }, [textBlock.style])

  // Generate animation styles
  const animationCSS = useMemo(() => {
    if (!textBlock.style?.animation) return {}
    return applyAnimation(textBlock.style.animation)
  }, [textBlock.style?.animation])

  // Combine all styles
  const combinedStyles = useMemo(() => ({
    ...styleCSS,
    ...animationCSS,
    left: textBlock.position.x,
    top: textBlock.position.y,
    width: textBlock.size?.width || 'auto',
    height: textBlock.size?.height || 'auto',
    minWidth: 100,
    minHeight: 40,
  }), [styleCSS, animationCSS, textBlock.position, textBlock.size])

  // Handle drag start and move
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (!isEditing || !onPositionChange) return
    
    e.preventDefault()
    e.stopPropagation()
    
    // Store initial mouse position and element position
    dragRef.current = {
      startX: e.clientX,
      startY: e.clientY,
      startPosX: textBlock.position.x,
      startPosY: textBlock.position.y,
    }
    setIsDragging(true)

    const handleMouseMove = (moveEvent: MouseEvent) => {
      if (!dragRef.current) return

      // Calculate delta from initial mouse position
      const deltaX = (moveEvent.clientX - dragRef.current.startX) / zoom
      const deltaY = (moveEvent.clientY - dragRef.current.startY) / zoom

      // Calculate new position from initial position + delta
      const textWidth = textBlock.size?.width || 100
      const textHeight = textBlock.size?.height || 40
      
      const newX = Math.max(0, Math.min(canvasSize.width - textWidth, dragRef.current.startPosX + deltaX))
      const newY = Math.max(0, Math.min(canvasSize.height - textHeight, dragRef.current.startPosY + deltaY))
      
      onPositionChange({ x: newX, y: newY })
    }

    const handleMouseUp = () => {
      setIsDragging(false)
      dragRef.current = null
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
  }, [isEditing, onPositionChange, textBlock.position, textBlock.size, zoom, canvasSize])

  // Handle content editing
  const handleContentEdit = (e: React.FocusEvent<HTMLDivElement>) => {
    if (!isEditing || !onContentChange) return
    onContentChange(e.currentTarget.textContent || '')
  }

  // Handle click
  const handleClick = () => {
    if (!isEditing) {
      // In view mode, show vocabulary tooltip if applicable
      if (textBlock.vocabularyWords && textBlock.vocabularyWords.length > 0) {
        setShowTooltip(true)
      }
    } else {
      onSelect?.()
    }
  }

  // Animation variants for entrance
  const animationVariants = {
    hidden: { opacity: 0, scale: 0.9 },
    visible: { 
      opacity: 1, 
      scale: 1,
      transition: {
        duration: 0.3,
        ease: [0.25, 0.46, 0.45, 0.94] as any,
      },
    },
  }

  // Don't render if no variant is selected
  if (!selectedVariant) {
    return null
  }

  // Inject animation keyframes if needed
  useEffect(() => {
    if (textBlock.style?.animation && textBlock.style.animation.type !== 'none') {
      const keyframes = generateAnimationKeyframes(textBlock.style.animation)
      if (keyframes) {
        const styleElement = document.createElement('style')
        styleElement.textContent = keyframes
        document.head.appendChild(styleElement)
        return () => {
          document.head.removeChild(styleElement)
        }
      }
    }
  }, [textBlock.style?.animation])

  const textContent = selectedVariant.content || editableContent

  return (
    <TextContainer
      isSelected={isSelected}
      isEditing={isEditing}
      isDragging={isDragging}
      style={combinedStyles}
      onMouseDown={handleMouseDown}
      onClick={handleClick}
    >
      <AnimatePresence>
        <AnimatedText
          initial="hidden"
          animate="visible"
          exit="hidden"
          variants={animationVariants}
        >
          {/* Vocabulary word tooltip */}
          {showTooltip && textBlock.vocabularyWords && textBlock.vocabularyWords.length > 0 && (
            <ClickAwayListener onClickAway={() => setShowTooltip(false)}>
              <Tooltip
                open={showTooltip}
                title={
                  <Box>
                    <Typography variant="subtitle2">Vocabulary Words:</Typography>
                    {textBlock.vocabularyWords.map((word, index) => (
                      <Typography key={index} variant="body2">
                        • {word}
                      </Typography>
                    ))}
                  </Box>
                }
                placement="top"
                arrow
              >
                <Box sx={{ width: '100%', height: '100%' }}>
                  {/* Content wrapper needed for tooltip */}
                  <div />
                </Box>
              </Tooltip>
            </ClickAwayListener>
          )}

          {/* Text content */}
          <Typography
            component="div"
            contentEditable={isEditing}
            suppressContentEditableWarning
            onBlur={handleContentEdit}
            sx={{
              width: '100%',
              height: '100%',
              outline: 'none',
              cursor: isEditing ? 'text' : 'default',
              
              // Apply any text-specific styles directly
              ...(textBlock.style?.text && {
                color: textBlock.style.text.color,
                fontSize: textBlock.style.text.fontSize,
                fontWeight: textBlock.style.text.fontWeight,
                fontFamily: textBlock.style.text.fontFamily,
                lineHeight: textBlock.style.text.lineHeight,
                letterSpacing: textBlock.style.text.letterSpacing,
                textAlign: textBlock.style.text.textAlign,
                textDecoration: textBlock.style.text.textDecoration,
                textTransform: textBlock.style.text.textTransform,
                wordSpacing: textBlock.style.text.wordSpacing,
              }),
            }}
          >
            {textContent}
          </Typography>

          {/* Removed variant indicator and interaction indicators - these should only show in the side panel */}
        </AnimatedText>
      </AnimatePresence>
    </TextContainer>
  )
}