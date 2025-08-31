import React, { useState, useEffect, useMemo } from 'react'
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
}

const TextContainer = styled(Box, {
  shouldForwardProp: (prop) => prop !== 'isSelected' && prop !== 'isEditing',
})<{ isSelected?: boolean; isEditing?: boolean }>(({ theme, isSelected, isEditing }) => ({
  position: 'absolute',
  cursor: isEditing ? 'move' : 'pointer',
  userSelect: isEditing ? 'none' : 'text',
  outline: isSelected ? `2px solid ${theme.palette.primary.main}` : 'none',
  outlineOffset: 2,
  transition: 'all 0.2s ease',
  
  '&:hover': {
    outline: isEditing ? `2px dashed ${theme.palette.primary.light}` : 'none',
  },
  
  // Add resize handles when selected
  ...(isSelected && {
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
}) => {
  const [isDragging, setIsDragging] = useState(false)
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 })
  const [showTooltip, setShowTooltip] = useState(false)
  const [editableContent, setEditableContent] = useState('')

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

    if (oldVariants.easy) {
      variants.push({
        id: 'variant-easy',
        content: oldVariants.easy,
        metadata: {
          difficulty: 'easy',
          ageRange: [3, 6],
          vocabularyLevel: 3,
          readingTime: Math.ceil(oldVariants.easy.split(' ').filter(Boolean).length / 200 * 60),
          wordCount: oldVariants.easy.split(' ').filter(Boolean).length,
          characterCount: oldVariants.easy.length,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        isDefault: true,
      })
    }

    if (oldVariants.medium) {
      variants.push({
        id: 'variant-medium',
        content: oldVariants.medium,
        metadata: {
          difficulty: 'medium',
          ageRange: [5, 8],
          vocabularyLevel: 5,
          readingTime: Math.ceil(oldVariants.medium.split(' ').filter(Boolean).length / 200 * 60),
          wordCount: oldVariants.medium.split(' ').filter(Boolean).length,
          characterCount: oldVariants.medium.length,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })
    }

    if (oldVariants.hard) {
      variants.push({
        id: 'variant-hard',
        content: oldVariants.hard,
        metadata: {
          difficulty: 'hard',
          ageRange: [7, 10],
          vocabularyLevel: 7,
          readingTime: Math.ceil(oldVariants.hard.split(' ').filter(Boolean).length / 200 * 60),
          wordCount: oldVariants.hard.split(' ').filter(Boolean).length,
          characterCount: oldVariants.hard.length,
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })
    }

    return variants
  }, [textBlock.variants])

  // Select the appropriate variant based on difficulty and age
  const selectedVariant = useMemo(() => {
    if (!normalizedVariants || normalizedVariants.length === 0) {
      return null
    }

    // If there's an active variant, use it
    if (textBlock.activeVariantId) {
      return normalizedVariants.find(v => v.id === textBlock.activeVariantId) || normalizedVariants[0]
    }

    // Otherwise, select based on difficulty and age
    const matchingVariants = normalizedVariants.filter(v => {
      const metadata = v.metadata
      const difficultyMatch = metadata.difficulty === difficulty
      const ageMatch = childAge >= metadata.ageRange[0] && childAge <= metadata.ageRange[1]
      return difficultyMatch && ageMatch
    })

    // If we have matching variants, pick the first one
    if (matchingVariants.length > 0) {
      return matchingVariants[0]
    }

    // Otherwise, try to find a variant that matches just the difficulty
    const difficultyVariant = normalizedVariants.find(v => v.metadata.difficulty === difficulty)
    if (difficultyVariant) {
      return difficultyVariant
    }

    // Fall back to the first variant or the default one
    return normalizedVariants.find(v => v.isDefault) || normalizedVariants[0]
  }, [normalizedVariants, textBlock.activeVariantId, difficulty, childAge])

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

  // Handle drag start
  const handleMouseDown = (e: React.MouseEvent) => {
    if (!isEditing || !onPositionChange) return
    
    e.preventDefault()
    setIsDragging(true)
    setDragStart({
      x: e.clientX - textBlock.position.x,
      y: e.clientY - textBlock.position.y,
    })
  }

  // Handle drag move
  useEffect(() => {
    if (!isDragging) return

    const handleMouseMove = (e: MouseEvent) => {
      const newX = Math.max(0, e.clientX - dragStart.x)
      const newY = Math.max(0, e.clientY - dragStart.y)
      onPositionChange?.({ x: newX, y: newY })
    }

    const handleMouseUp = () => {
      setIsDragging(false)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)

    return () => {
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }
  }, [isDragging, dragStart, onPositionChange])

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

          {/* Variant indicator (only in edit mode) */}
          {isEditing && (
            <Box
              sx={{
                position: 'absolute',
                top: -20,
                right: 0,
                fontSize: 11,
                backgroundColor: 'primary.main',
                color: 'white',
                px: 1,
                py: 0.25,
                borderRadius: 1,
                opacity: 0.8,
              }}
            >
              {selectedVariant.metadata.difficulty} | Age {selectedVariant.metadata.ageRange[0]}-{selectedVariant.metadata.ageRange[1]}
            </Box>
          )}

          {/* Interaction indicators */}
          {textBlock.interactions && textBlock.interactions.length > 0 && (
            <Box
              sx={{
                position: 'absolute',
                bottom: -20,
                left: 0,
                display: 'flex',
                gap: 0.5,
              }}
            >
              {textBlock.interactions.map((interaction, index) => (
                <Box
                  key={index}
                  sx={{
                    width: 16,
                    height: 16,
                    borderRadius: '50%',
                    backgroundColor: 'secondary.main',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 10,
                    color: 'white',
                  }}
                  title={`${interaction.type}: ${interaction.action}`}
                >
                  {index + 1}
                </Box>
              ))}
            </Box>
          )}
        </AnimatedText>
      </AnimatePresence>
    </TextContainer>
  )
}