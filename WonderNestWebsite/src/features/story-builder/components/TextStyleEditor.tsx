import React, { useState, useEffect, useCallback } from 'react'
import {
  Box,
  Paper,
  Tabs,
  Tab,
  TextField,
  Slider,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  IconButton,
  Button,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Grid,
  Chip,
  Tooltip,
  ToggleButtonGroup,
  ToggleButton,
  Divider,
  Stack,
  FormLabel,
  Switch,
  FormControlLabel,
} from '@mui/material'
import {
  ExpandMore as ExpandMoreIcon,
  FormatBold as BoldIcon,
  FormatItalic as ItalicIcon,
  FormatUnderlined as UnderlineIcon,
  FormatAlignLeft as AlignLeftIcon,
  FormatAlignCenter as AlignCenterIcon,
  FormatAlignRight as AlignRightIcon,
  FormatAlignJustify as AlignJustifyIcon,
  Palette as PaletteIcon,
  Gradient as GradientIcon,
  Image as ImageIcon,
  Pattern as PatternIcon,
  Animation as AnimationIcon,
  AutoFixHigh as EffectsIcon,
  Add as AddIcon,
  Delete as DeleteIcon,
  FileCopy as CopyIcon,
  Visibility as PreviewIcon,
  Save as SaveIcon,
  RestartAlt as ResetIcon,
} from '@mui/icons-material'
import { HexColorPicker } from 'react-colorful'
import { styled } from '@mui/material/styles'

import {
  TextBlock,
  TextBlockStyle,
  TextVariant,
  BackgroundStyle,
  TextStyle,
  TextEffects,
  TextAnimation,
  GradientStop,
  StylePreset,
} from '../types/story'
import { defaultStylePresets } from '../utils/styleUtils'
import { VariantManager } from './VariantManager'

interface TextStyleEditorProps {
  textBlock: TextBlock
  onStyleChange: (style: TextBlockStyle) => void
  onVariantChange: (variants: TextVariant[]) => void
  presets?: StylePreset[]
  allowCustomStyles?: boolean
  validationRules?: any[]
}

const TabPanel = ({ children, value, index }: any) => (
  <Box hidden={value !== index} sx={{ pt: 2 }}>
    {value === index && children}
  </Box>
)

const ColorPickerWrapper = styled(Box)(({ theme }) => ({
  position: 'relative',
  '& .react-colorful': {
    width: '100%',
    height: 200,
    marginTop: theme.spacing(1),
  },
}))

export const TextStyleEditor: React.FC<TextStyleEditorProps> = ({
  textBlock,
  onStyleChange,
  onVariantChange,
  presets = defaultStylePresets,
  allowCustomStyles = true,
}) => {
  const [activeTab, setActiveTab] = useState(0)
  const [currentStyle, setCurrentStyle] = useState<TextBlockStyle>(textBlock.style || {})
  const [variants, setVariants] = useState<TextVariant[]>(textBlock.variants || [])
  const [selectedPreset, setSelectedPreset] = useState<string | null>(null)
  const [showColorPicker, setShowColorPicker] = useState<string | null>(null)

  // Background state
  const [backgroundType, setBackgroundType] = useState<BackgroundStyle['type']>(
    currentStyle.background?.type || 'solid'
  )
  const [backgroundColor, setBackgroundColor] = useState(
    currentStyle.background?.color || '#ffffff'
  )
  const [backgroundOpacity, setBackgroundOpacity] = useState(
    currentStyle.background?.opacity || 1
  )
  const [gradientStops, setGradientStops] = useState<GradientStop[]>(
    currentStyle.background?.gradient?.colors || [
      { color: '#ffffff', position: 0 },
      { color: '#000000', position: 100 },
    ]
  )

  // Text style state
  const [textColor, setTextColor] = useState(currentStyle.text?.color || '#000000')
  const [fontSize, setFontSize] = useState(currentStyle.text?.fontSize || 16)
  const [fontWeight, setFontWeight] = useState(currentStyle.text?.fontWeight || 400)
  const [textAlign, setTextAlign] = useState(currentStyle.text?.textAlign || 'left')
  const [lineHeight, setLineHeight] = useState(currentStyle.text?.lineHeight || 1.5)

  // Effects state
  const [enableShadow, setEnableShadow] = useState(!!currentStyle.effects?.shadow)
  const [enableGlow, setEnableGlow] = useState(!!currentStyle.effects?.glow)
  const [animationType, setAnimationType] = useState<TextAnimation['type']>(
    currentStyle.animation?.type || 'none'
  )

  // Update the style when any property changes
  useEffect(() => {
    const newStyle: TextBlockStyle = {
      ...currentStyle,
      background: {
        type: backgroundType,
        color: backgroundColor,
        opacity: backgroundOpacity,
        ...(backgroundType === 'gradient' && {
          gradient: {
            type: 'linear',
            colors: gradientStops,
            angle: 45,
          },
        }),
        padding: { top: 12, right: 16, bottom: 12, left: 16 },
        borderRadius: { topLeft: 4, topRight: 4, bottomLeft: 4, bottomRight: 4 },
      },
      text: {
        color: textColor,
        fontSize,
        fontWeight,
        textAlign,
        lineHeight,
      },
      effects: {
        ...(enableShadow && {
          shadow: [
            {
              x: 2,
              y: 2,
              blur: 4,
              color: 'rgba(0,0,0,0.2)',
            },
          ],
        }),
        ...(enableGlow && {
          glow: {
            color: textColor,
            radius: 10,
            intensity: 0.5,
          },
        }),
      },
      ...(animationType !== 'none' && {
        animation: {
          type: animationType,
          duration: 1000,
          iteration: 'infinite',
          easing: 'ease-in-out',
        },
      }),
    }

    setCurrentStyle(newStyle)
    onStyleChange(newStyle)
  }, [
    backgroundType,
    backgroundColor,
    backgroundOpacity,
    gradientStops,
    textColor,
    fontSize,
    fontWeight,
    textAlign,
    lineHeight,
    enableShadow,
    enableGlow,
    animationType,
  ])

  // Variant handling is now managed by the VariantManager component

  const handlePresetSelect = (presetId: string) => {
    const preset = presets.find((p) => p.id === presetId)
    if (preset) {
      setSelectedPreset(presetId)
      setCurrentStyle(preset.style)
      onStyleChange(preset.style)
      
      // Update individual state values from preset
      if (preset.style.background) {
        setBackgroundType(preset.style.background.type)
        setBackgroundColor(preset.style.background.color || '#ffffff')
        setBackgroundOpacity(preset.style.background.opacity || 1)
      }
      if (preset.style.text) {
        setTextColor(preset.style.text.color || '#000000')
        setFontSize(preset.style.text.fontSize as number || 16)
        setFontWeight(preset.style.text.fontWeight as number || 400)
        setTextAlign(preset.style.text.textAlign || 'left')
      }
    }
  }

  const handleAddGradientStop = () => {
    const newStop: GradientStop = {
      color: '#888888',
      position: 50,
    }
    setGradientStops([...gradientStops, newStop])
  }

  return (
    <Paper elevation={2} sx={{ p: 2, height: '100%', overflow: 'auto' }}>
      <Typography variant="h6" gutterBottom>
        Text Style Editor
      </Typography>

      <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tab label="Style" icon={<PaletteIcon />} iconPosition="start" />
        <Tab label="Variants" icon={<CopyIcon />} iconPosition="start" />
        <Tab label="Presets" icon={<SaveIcon />} iconPosition="start" />
        <Tab label="Effects" icon={<EffectsIcon />} iconPosition="start" />
      </Tabs>

      <TabPanel value={activeTab} index={0}>
        {/* Background Section */}
        <Accordion defaultExpanded>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography>Background</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Stack spacing={2}>
              <FormControl fullWidth size="small">
                <InputLabel>Background Type</InputLabel>
                <Select
                  value={backgroundType}
                  onChange={(e) => setBackgroundType(e.target.value as BackgroundStyle['type'])}
                  label="Background Type"
                >
                  <MenuItem value="solid">Solid Color</MenuItem>
                  <MenuItem value="gradient">Gradient</MenuItem>
                  <MenuItem value="image">Image</MenuItem>
                  <MenuItem value="pattern">Pattern</MenuItem>
                </Select>
              </FormControl>

              {backgroundType === 'solid' && (
                <>
                  <Box>
                    <FormLabel>Background Color</FormLabel>
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        backgroundColor,
                        border: '1px solid #ccc',
                        borderRadius: 1,
                        cursor: 'pointer',
                        mt: 1,
                      }}
                      onClick={() => setShowColorPicker('background')}
                    />
                    {showColorPicker === 'background' && (
                      <ColorPickerWrapper>
                        <HexColorPicker color={backgroundColor} onChange={setBackgroundColor} />
                        <Button
                          size="small"
                          onClick={() => setShowColorPicker(null)}
                          sx={{ mt: 1 }}
                        >
                          Done
                        </Button>
                      </ColorPickerWrapper>
                    )}
                  </Box>

                  <Box>
                    <FormLabel>Opacity</FormLabel>
                    <Slider
                      value={backgroundOpacity}
                      onChange={(_, v) => setBackgroundOpacity(v as number)}
                      min={0}
                      max={1}
                      step={0.1}
                      valueLabelDisplay="auto"
                    />
                  </Box>
                </>
              )}

              {backgroundType === 'gradient' && (
                <>
                  <Typography variant="subtitle2">Gradient Stops</Typography>
                  {gradientStops.map((stop, index) => (
                    <Box key={index} sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                      <Box
                        sx={{
                          width: 30,
                          height: 30,
                          backgroundColor: stop.color,
                          border: '1px solid #ccc',
                          borderRadius: 1,
                          cursor: 'pointer',
                        }}
                        onClick={() => {
                          // Color picker for gradient stops would go here
                        }}
                      />
                      <TextField
                        size="small"
                        type="number"
                        value={stop.position}
                        onChange={(e) => {
                          const newStops = [...gradientStops]
                          newStops[index].position = Number(e.target.value)
                          setGradientStops(newStops)
                        }}
                        inputProps={{ min: 0, max: 100 }}
                        sx={{ width: 80 }}
                      />
                      <IconButton
                        size="small"
                        onClick={() => setGradientStops(gradientStops.filter((_, i) => i !== index))}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  ))}
                  <Button
                    startIcon={<AddIcon />}
                    onClick={handleAddGradientStop}
                    size="small"
                    variant="outlined"
                  >
                    Add Stop
                  </Button>
                </>
              )}
            </Stack>
          </AccordionDetails>
        </Accordion>

        {/* Text Style Section */}
        <Accordion defaultExpanded>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography>Text Style</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Stack spacing={2}>
              <Box>
                <FormLabel>Text Color</FormLabel>
                <Box
                  sx={{
                    width: 40,
                    height: 40,
                    backgroundColor: textColor,
                    border: '1px solid #ccc',
                    borderRadius: 1,
                    cursor: 'pointer',
                    mt: 1,
                  }}
                  onClick={() => setShowColorPicker('text')}
                />
                {showColorPicker === 'text' && (
                  <ColorPickerWrapper>
                    <HexColorPicker color={textColor} onChange={setTextColor} />
                    <Button
                      size="small"
                      onClick={() => setShowColorPicker(null)}
                      sx={{ mt: 1 }}
                    >
                      Done
                    </Button>
                  </ColorPickerWrapper>
                )}
              </Box>

              <Box>
                <FormLabel>Font Size</FormLabel>
                <Slider
                  value={fontSize as number}
                  onChange={(_, v) => setFontSize(v as number)}
                  min={12}
                  max={72}
                  valueLabelDisplay="auto"
                />
              </Box>

              <Box>
                <FormLabel>Font Weight</FormLabel>
                <ToggleButtonGroup
                  value={fontWeight}
                  exclusive
                  onChange={(_, v) => v && setFontWeight(v)}
                  size="small"
                >
                  <ToggleButton value={300}>Light</ToggleButton>
                  <ToggleButton value={400}>Regular</ToggleButton>
                  <ToggleButton value={600}>Semi Bold</ToggleButton>
                  <ToggleButton value={700}>Bold</ToggleButton>
                </ToggleButtonGroup>
              </Box>

              <Box>
                <FormLabel>Text Align</FormLabel>
                <ToggleButtonGroup
                  value={textAlign}
                  exclusive
                  onChange={(_, v) => v && setTextAlign(v)}
                  size="small"
                >
                  <ToggleButton value="left">
                    <AlignLeftIcon />
                  </ToggleButton>
                  <ToggleButton value="center">
                    <AlignCenterIcon />
                  </ToggleButton>
                  <ToggleButton value="right">
                    <AlignRightIcon />
                  </ToggleButton>
                  <ToggleButton value="justify">
                    <AlignJustifyIcon />
                  </ToggleButton>
                </ToggleButtonGroup>
              </Box>

              <Box>
                <FormLabel>Line Height</FormLabel>
                <Slider
                  value={lineHeight}
                  onChange={(_, v) => setLineHeight(v as number)}
                  min={1}
                  max={3}
                  step={0.1}
                  valueLabelDisplay="auto"
                />
              </Box>
            </Stack>
          </AccordionDetails>
        </Accordion>
      </TabPanel>

      <TabPanel value={activeTab} index={1}>
        {/* Variants Section - Using VariantManager for comprehensive variant editing */}
        <VariantManager
          variants={variants}
          activeVariantId={textBlock.activeVariantId}
          onVariantsChange={(updatedVariants) => {
            setVariants(updatedVariants)
            onVariantChange(updatedVariants)
          }}
          onActiveVariantChange={(variantId) => {
            // This would need to be passed up to update the textBlock's activeVariantId
            // For now, we'll just track it locally
          }}
        />
      </TabPanel>

      <TabPanel value={activeTab} index={2}>
        {/* Presets Section */}
        <Grid container spacing={2}>
          {presets.map((preset) => (
            <Grid item xs={6} key={preset.id}>
              <Paper
                variant="outlined"
                sx={{
                  p: 2,
                  cursor: 'pointer',
                  border: selectedPreset === preset.id ? 2 : 1,
                  borderColor: selectedPreset === preset.id ? 'primary.main' : 'divider',
                  '&:hover': {
                    borderColor: 'primary.main',
                  },
                }}
                onClick={() => handlePresetSelect(preset.id)}
              >
                <Typography variant="subtitle2" gutterBottom>
                  {preset.name}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {preset.description}
                </Typography>
                <Box sx={{ mt: 1 }}>
                  {preset.tags.map((tag) => (
                    <Chip key={tag} label={tag} size="small" sx={{ mr: 0.5, mb: 0.5 }} />
                  ))}
                </Box>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </TabPanel>

      <TabPanel value={activeTab} index={3}>
        {/* Effects Section */}
        <Stack spacing={2}>
          <FormControlLabel
            control={
              <Switch
                checked={enableShadow}
                onChange={(e) => setEnableShadow(e.target.checked)}
              />
            }
            label="Text Shadow"
          />

          <FormControlLabel
            control={
              <Switch
                checked={enableGlow}
                onChange={(e) => setEnableGlow(e.target.checked)}
              />
            }
            label="Text Glow"
          />

          <FormControl fullWidth size="small">
            <InputLabel>Animation</InputLabel>
            <Select
              value={animationType}
              onChange={(e) => setAnimationType(e.target.value as TextAnimation['type'])}
              label="Animation"
            >
              <MenuItem value="none">None</MenuItem>
              <MenuItem value="pulse">Pulse</MenuItem>
              <MenuItem value="glow">Glow</MenuItem>
              <MenuItem value="shimmer">Shimmer</MenuItem>
              <MenuItem value="bounce">Bounce</MenuItem>
              <MenuItem value="fade">Fade</MenuItem>
              <MenuItem value="slide">Slide</MenuItem>
              <MenuItem value="typewriter">Typewriter</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </TabPanel>
    </Paper>
  )
}