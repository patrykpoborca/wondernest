import {
  TextBlockStyle,
  StylePreset,
  BackgroundStyle,
  TextStyle,
  TextEffects,
  TextAnimation,
  GradientStop,
} from '../types/story'

/**
 * Default style presets for quick application
 */
export const defaultStylePresets: StylePreset[] = [
  {
    id: 'preset-title',
    name: 'Story Title',
    description: 'Bold and eye-catching title style',
    category: 'title',
    style: {
      background: {
        type: 'gradient',
        gradient: {
          type: 'linear',
          colors: [
            { color: '#FFD700', position: 0, opacity: 0.8 },
            { color: '#FFA500', position: 100, opacity: 0.8 },
          ],
          angle: 45,
        },
        padding: { top: 20, right: 30, bottom: 20, left: 30 },
        borderRadius: { topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 12 },
      },
      text: {
        color: '#FFFFFF',
        fontSize: 36,
        fontWeight: 700,
        textAlign: 'center',
        textTransform: 'uppercase',
        letterSpacing: 2,
      },
      effects: {
        shadow: [
          {
            x: 2,
            y: 2,
            blur: 4,
            color: 'rgba(0,0,0,0.3)',
          },
        ],
      },
    },
    thumbnail: '',
    tags: ['title', 'header', 'bold'],
    isCustom: false,
    isGlobal: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    usageCount: 0,
  },
  {
    id: 'preset-dialogue',
    name: 'Character Dialogue',
    description: 'Speech bubble style for character dialogue',
    category: 'dialogue',
    style: {
      background: {
        type: 'solid',
        color: '#E3F2FD',
        opacity: 0.95,
        padding: { top: 12, right: 20, bottom: 12, left: 20 },
        borderRadius: { topLeft: 20, topRight: 20, bottomLeft: 4, bottomRight: 20 },
      },
      text: {
        color: '#1976D2',
        fontSize: 18,
        fontWeight: 400,
        textAlign: 'left',
        lineHeight: 1.6,
      },
    },
    thumbnail: '',
    tags: ['dialogue', 'speech', 'conversation'],
    isCustom: false,
    isGlobal: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    usageCount: 0,
  },
  {
    id: 'preset-vocabulary',
    name: 'Vocabulary Word',
    description: 'Highlighted style for vocabulary words',
    category: 'vocabulary',
    style: {
      background: {
        type: 'solid',
        color: '#FFF3E0',
        opacity: 1,
        padding: { top: 8, right: 16, bottom: 8, left: 16 },
        borderRadius: { topLeft: 4, topRight: 4, bottomLeft: 4, bottomRight: 4 },
      },
      text: {
        color: '#E65100',
        fontSize: 20,
        fontWeight: 600,
        textAlign: 'center',
      },
      effects: {
        glow: {
          color: '#FFB74D',
          radius: 8,
          intensity: 0.5,
        },
      },
      animation: {
        type: 'pulse',
        duration: 2000,
        iteration: 'infinite',
        easing: 'ease-in-out',
      },
    },
    thumbnail: '',
    tags: ['vocabulary', 'learning', 'highlight'],
    isCustom: false,
    isGlobal: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    usageCount: 0,
  },
  {
    id: 'preset-narration',
    name: 'Narration',
    description: 'Clean and readable narration text',
    category: 'narration',
    style: {
      background: {
        type: 'solid',
        color: '#FFFFFF',
        opacity: 0.9,
        padding: { top: 16, right: 24, bottom: 16, left: 24 },
        borderRadius: { topLeft: 8, topRight: 8, bottomLeft: 8, bottomRight: 8 },
      },
      text: {
        color: '#424242',
        fontSize: 18,
        fontWeight: 400,
        textAlign: 'justify',
        lineHeight: 1.8,
      },
    },
    thumbnail: '',
    tags: ['narration', 'story', 'reading'],
    isCustom: false,
    isGlobal: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    usageCount: 0,
  },
  {
    id: 'preset-emphasis',
    name: 'Emphasis',
    description: 'Draw attention to important text',
    category: 'emphasis',
    style: {
      background: {
        type: 'gradient',
        gradient: {
          type: 'radial',
          colors: [
            { color: '#FF6B6B', position: 0, opacity: 0.2 },
            { color: '#FF6B6B', position: 100, opacity: 0 },
          ],
        },
        padding: { top: 12, right: 20, bottom: 12, left: 20 },
        borderRadius: { topLeft: 8, topRight: 8, bottomLeft: 8, bottomRight: 8 },
      },
      text: {
        color: '#D32F2F',
        fontSize: 22,
        fontWeight: 700,
        textAlign: 'center',
        textTransform: 'uppercase',
      },
      animation: {
        type: 'bounce',
        duration: 1000,
        delay: 500,
        iteration: 2,
        easing: 'ease-out',
      },
    },
    thumbnail: '',
    tags: ['emphasis', 'important', 'highlight'],
    isCustom: false,
    isGlobal: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    usageCount: 0,
  },
  {
    id: 'preset-magical',
    name: 'Magical Text',
    description: 'Sparkly, magical effect for fantasy stories',
    category: 'seasonal',
    style: {
      background: {
        type: 'gradient',
        gradient: {
          type: 'linear',
          colors: [
            { color: '#9C27B0', position: 0, opacity: 0.3 },
            { color: '#3F51B5', position: 50, opacity: 0.3 },
            { color: '#00BCD4', position: 100, opacity: 0.3 },
          ],
          angle: 135,
        },
        padding: { top: 16, right: 24, bottom: 16, left: 24 },
        borderRadius: { topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 16 },
        blur: 8,
      },
      text: {
        color: '#FFFFFF',
        fontSize: 20,
        fontWeight: 500,
        textAlign: 'center',
      },
      effects: {
        glow: {
          color: '#E1BEE7',
          radius: 12,
          intensity: 0.8,
        },
        shadow: [
          {
            x: 0,
            y: 0,
            blur: 10,
            color: 'rgba(156, 39, 176, 0.5)',
          },
        ],
      },
      animation: {
        type: 'shimmer',
        duration: 3000,
        iteration: 'infinite',
        easing: 'linear',
      },
    },
    thumbnail: '',
    tags: ['magical', 'fantasy', 'sparkle'],
    isCustom: false,
    isGlobal: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    usageCount: 0,
  },
]

/**
 * Generate CSS from TextBlockStyle
 */
export const generateStyleCSS = (style: TextBlockStyle): React.CSSProperties => {
  const css: React.CSSProperties = {}

  // Background styles
  if (style.background) {
    const bg = style.background
    
    if (bg.type === 'solid') {
      css.backgroundColor = bg.color
      css.opacity = bg.opacity
    } else if (bg.type === 'gradient' && bg.gradient) {
      const gradient = bg.gradient
      if (gradient.type === 'linear') {
        const stops = gradient.colors
          .map((stop) => `${stop.color} ${stop.position}%`)
          .join(', ')
        css.background = `linear-gradient(${gradient.angle || 0}deg, ${stops})`
      } else if (gradient.type === 'radial') {
        const stops = gradient.colors
          .map((stop) => `${stop.color} ${stop.position}%`)
          .join(', ')
        css.background = `radial-gradient(circle, ${stops})`
      }
    } else if (bg.type === 'image' && bg.image) {
      css.backgroundImage = `url(${bg.image.url})`
      css.backgroundSize = bg.image.size || 'cover'
      css.backgroundPosition = bg.image.position || 'center'
      css.backgroundRepeat = bg.image.repeat || 'no-repeat'
    }

    // Padding
    if (bg.padding) {
      css.paddingTop = bg.padding.top
      css.paddingRight = bg.padding.right
      css.paddingBottom = bg.padding.bottom
      css.paddingLeft = bg.padding.left
    }

    // Border radius
    if (bg.borderRadius) {
      css.borderTopLeftRadius = bg.borderRadius.topLeft
      css.borderTopRightRadius = bg.borderRadius.topRight
      css.borderBottomLeftRadius = bg.borderRadius.bottomLeft
      css.borderBottomRightRadius = bg.borderRadius.bottomRight
    }

    // Backdrop blur
    if (bg.blur) {
      css.backdropFilter = `blur(${bg.blur}px)`
    }

    // Mix blend mode
    if (bg.mixBlendMode) {
      css.mixBlendMode = bg.mixBlendMode as any
    }
  }

  // Text styles
  if (style.text) {
    const text = style.text
    css.color = text.color
    css.fontSize = typeof text.fontSize === 'number' ? text.fontSize : undefined
    css.fontWeight = text.fontWeight
    css.fontFamily = text.fontFamily
    css.lineHeight = text.lineHeight
    css.letterSpacing = text.letterSpacing
    css.textAlign = text.textAlign
    css.textDecoration = text.textDecoration
    css.textTransform = text.textTransform
    css.wordSpacing = text.wordSpacing
  }

  // Effects
  if (style.effects) {
    const effects = style.effects
    const shadows: string[] = []

    if (effects.shadow) {
      effects.shadow.forEach((shadow) => {
        const inset = shadow.inset ? 'inset ' : ''
        shadows.push(
          `${inset}${shadow.x}px ${shadow.y}px ${shadow.blur}px ${shadow.spread || 0}px ${shadow.color}`
        )
      })
    }

    if (effects.glow) {
      shadows.push(
        `0 0 ${effects.glow.radius}px ${effects.glow.color}`
      )
    }

    if (shadows.length > 0) {
      css.textShadow = shadows.join(', ')
    }

    if (effects.outline) {
      css.WebkitTextStroke = `${effects.outline.width}px ${effects.outline.color}`
    }

    if (effects.filter) {
      css.filter = effects.filter
    }
  }

  return css
}

/**
 * Generate animation keyframes
 */
export const generateAnimationKeyframes = (animation: TextAnimation): string => {
  if (!animation || animation.type === 'none') return ''

  const animationMap: Record<string, string> = {
    pulse: `
      @keyframes pulse {
        0%, 100% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.05); opacity: 0.9; }
      }
    `,
    glow: `
      @keyframes glow {
        0%, 100% { filter: brightness(1); }
        50% { filter: brightness(1.2); }
      }
    `,
    shimmer: `
      @keyframes shimmer {
        0% { background-position: -100% 0; }
        100% { background-position: 100% 0; }
      }
    `,
    bounce: `
      @keyframes bounce {
        0%, 100% { transform: translateY(0); }
        25% { transform: translateY(-10px); }
        75% { transform: translateY(5px); }
      }
    `,
    fade: `
      @keyframes fade {
        0% { opacity: 0; }
        100% { opacity: 1; }
      }
    `,
    slide: `
      @keyframes slide {
        0% { transform: translateX(-100%); opacity: 0; }
        100% { transform: translateX(0); opacity: 1; }
      }
    `,
    typewriter: `
      @keyframes typewriter {
        from { width: 0; }
        to { width: 100%; }
      }
    `,
  }

  return animationMap[animation.type] || ''
}

/**
 * Apply animation to element
 */
export const applyAnimation = (animation: TextAnimation): React.CSSProperties => {
  if (!animation || animation.type === 'none') return {}

  const duration = animation.duration || 1000
  const delay = animation.delay || 0
  const iteration = animation.iteration === 'infinite' ? 'infinite' : animation.iteration || 1
  const easing = animation.easing || 'ease-in-out'

  return {
    animation: `${animation.type} ${duration}ms ${easing} ${delay}ms ${iteration}`,
  }
}

/**
 * Validate text content for child safety
 */
export const validateTextContent = (content: string): { isValid: boolean; issues: string[] } => {
  const issues: string[] = []
  
  // Check for inappropriate language (simplified check)
  const inappropriateWords = ['bad', 'evil', 'scary', 'monster'] // This would be a more comprehensive list
  const contentLower = content.toLowerCase()
  
  inappropriateWords.forEach((word) => {
    if (contentLower.includes(word)) {
      issues.push(`Contains potentially inappropriate word: "${word}"`)
    }
  })

  // Check content length
  if (content.length > 500) {
    issues.push('Text is too long for young readers (max 500 characters)')
  }

  // Check readability (simple check for sentence length)
  const sentences = content.split(/[.!?]/).filter(Boolean)
  const longSentences = sentences.filter((s) => s.split(' ').length > 15)
  
  if (longSentences.length > 0) {
    issues.push('Contains sentences that may be too complex for young readers')
  }

  return {
    isValid: issues.length === 0,
    issues,
  }
}

/**
 * Calculate reading difficulty score
 */
export const calculateReadingDifficulty = (content: string): number => {
  const words = content.split(/\s+/).filter(Boolean)
  const sentences = content.split(/[.!?]+/).filter(Boolean)
  const syllables = words.reduce((count, word) => {
    // Simple syllable counting (not perfect but good enough)
    return count + word.replace(/[^aeiouAEIOU]/g, '').length || 1
  }, 0)

  if (sentences.length === 0 || words.length === 0) return 0

  // Flesch Reading Ease Score (simplified)
  const score = 206.835 - 1.015 * (words.length / sentences.length) - 84.6 * (syllables / words.length)
  
  // Convert to 1-10 scale
  return Math.max(1, Math.min(10, Math.round((100 - score) / 10)))
}

/**
 * Get responsive style based on viewport
 */
export const getResponsiveStyle = (
  baseStyle: TextBlockStyle,
  viewport: 'mobile' | 'tablet' | 'desktop'
): TextBlockStyle => {
  if (!baseStyle.responsive) return baseStyle

  const responsiveOverrides = baseStyle.responsive[viewport]
  if (!responsiveOverrides) return baseStyle

  return {
    ...baseStyle,
    ...responsiveOverrides,
    background: baseStyle.background ? {
      ...baseStyle.background,
      ...responsiveOverrides.background,
    } : responsiveOverrides.background,
    text: baseStyle.text ? {
      ...baseStyle.text,
      ...responsiveOverrides.text,
    } : responsiveOverrides.text,
    effects: baseStyle.effects ? {
      ...baseStyle.effects,
      ...responsiveOverrides.effects,
    } : responsiveOverrides.effects,
  }
}

/**
 * Export style as JSON for sharing
 */
export const exportStyleAsJSON = (style: TextBlockStyle): string => {
  return JSON.stringify(style, null, 2)
}

/**
 * Import style from JSON
 */
export const importStyleFromJSON = (json: string): TextBlockStyle | null => {
  try {
    const style = JSON.parse(json) as TextBlockStyle
    // Basic validation
    if (typeof style !== 'object') return null
    return style
  } catch (error) {
    console.error('Failed to import style:', error)
    return null
  }
}