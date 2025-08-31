import React, { useState, useRef, useCallback } from 'react'
import { Box, IconButton, Tooltip } from '@mui/material'
import {
  Delete as DeleteIcon,
  DragIndicator as DragIcon,
  AspectRatio as ResizeIcon,
  RotateRight as RotateIcon,
  Flip as FlipHorizontalIcon,
  FlipCameraAndroid as FlipVerticalIcon,
} from '@mui/icons-material'
import { styled } from '@mui/material/styles'

const ImageContainer = styled(Box)<{ 
  selected?: boolean 
  zoom?: number 
}>(({ theme, selected, zoom = 1 }) => ({
  position: 'absolute',
  cursor: 'move',
  border: selected ? `2px solid ${theme.palette.primary.main}` : `1px solid transparent`,
  borderRadius: theme.spacing(1),
  overflow: 'hidden',
  backgroundColor: 'transparent',
  transition: 'border-color 0.2s ease-in-out',
  transformOrigin: 'top left',
  '&:hover': {
    border: selected ? `2px solid ${theme.palette.primary.main}` : `1px solid ${theme.palette.grey[400]}`,
    boxShadow: 'rgba(0, 0, 0, 0.15) 0px 5px 15px 0px',
  },
  '& .image-controls': {
    position: 'absolute',
    top: 0,
    right: 0,
    display: 'flex',
    gap: theme.spacing(0.5),
    padding: theme.spacing(0.5),
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    borderBottomLeftRadius: theme.spacing(1),
    opacity: 0,
    transition: 'opacity 0.2s',
  },
  '&:hover .image-controls': {
    opacity: 1,
  },
  '& .resize-handle': {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 20,
    height: 20,
    backgroundColor: theme.palette.primary.main,
    cursor: 'nwse-resize',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    borderTopLeftRadius: theme.spacing(1),
    opacity: 0,
    transition: 'opacity 0.2s',
  },
  '&:hover .resize-handle': {
    opacity: 1,
  },
}))

const StyledImage = styled('img')({
  width: '100%',
  height: '100%',
  objectFit: 'contain',
  userSelect: 'none',
  pointerEvents: 'none',
  backgroundColor: 'transparent',
})

interface DraggableImageProps {
  id: string
  imageUrl: string
  position: { x: number; y: number }
  size: { width: number; height: number }
  rotation?: number
  flipHorizontal?: boolean
  flipVertical?: boolean
  selected?: boolean
  zoom?: number
  onUpdate: (id: string, updates: {
    position?: { x: number; y: number }
    size?: { width: number; height: number }
    rotation?: number
    flipHorizontal?: boolean
    flipVertical?: boolean
  }) => void
  onDelete: (id: string) => void
  onSelect: (id: string) => void
  isReadOnly?: boolean
  canvasSize?: { width: number; height: number }
}

export const DraggableImage: React.FC<DraggableImageProps> = ({
  id,
  imageUrl,
  position,
  size,
  rotation = 0,
  flipHorizontal = false,
  flipVertical = false,
  selected = false,
  zoom = 1,
  onUpdate,
  onDelete,
  onSelect,
  isReadOnly = false,
  canvasSize = { width: 800, height: 600 },
}) => {
  const [isDragging, setIsDragging] = useState(false)
  const [isResizing, setIsResizing] = useState(false)
  const dragRef = useRef<{
    startX: number
    startY: number
    startPosX: number
    startPosY: number
  } | null>(null)
  const resizeRef = useRef<{
    startX: number
    startY: number
    startWidth: number
    startHeight: number
  } | null>(null)

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (isReadOnly) return
    e.stopPropagation()
    
    if (!selected) {
      onSelect(id)
    }

    dragRef.current = {
      startX: e.clientX,
      startY: e.clientY,
      startPosX: position.x,
      startPosY: position.y,
    }
    setIsDragging(true)

    const handleMouseMove = (moveEvent: MouseEvent) => {
      if (!dragRef.current) return

      const deltaX = (moveEvent.clientX - dragRef.current.startX) / zoom
      const deltaY = (moveEvent.clientY - dragRef.current.startY) / zoom

      const newX = Math.max(0, Math.min(canvasSize.width - size.width, dragRef.current.startPosX + deltaX))
      const newY = Math.max(0, Math.min(canvasSize.height - size.height, dragRef.current.startPosY + deltaY))

      onUpdate(id, { position: { x: newX, y: newY } })
    }

    const handleMouseUp = () => {
      setIsDragging(false)
      dragRef.current = null
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
  }, [id, position, size, zoom, selected, onUpdate, onSelect, isReadOnly, canvasSize])

  const handleResizeMouseDown = useCallback((e: React.MouseEvent) => {
    if (isReadOnly) return
    e.stopPropagation()

    resizeRef.current = {
      startX: e.clientX,
      startY: e.clientY,
      startWidth: size.width,
      startHeight: size.height,
    }
    setIsResizing(true)

    const handleMouseMove = (moveEvent: MouseEvent) => {
      if (!resizeRef.current) return

      const deltaX = (moveEvent.clientX - resizeRef.current.startX) / zoom
      const deltaY = (moveEvent.clientY - resizeRef.current.startY) / zoom

      // Maintain aspect ratio
      const aspectRatio = resizeRef.current.startWidth / resizeRef.current.startHeight
      let newWidth = Math.max(50, Math.min(canvasSize.width - position.x, resizeRef.current.startWidth + deltaX))
      let newHeight = newWidth / aspectRatio

      // Check if height exceeds bounds
      if (newHeight > canvasSize.height - position.y) {
        newHeight = canvasSize.height - position.y
        newWidth = newHeight * aspectRatio
      }

      // Ensure minimum size
      newWidth = Math.max(50, newWidth)
      newHeight = Math.max(50, newHeight)

      onUpdate(id, { size: { width: newWidth, height: newHeight } })
    }

    const handleMouseUp = () => {
      setIsResizing(false)
      resizeRef.current = null
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
  }, [id, position, size, zoom, onUpdate, isReadOnly, canvasSize])

  const handleDelete = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onDelete(id)
  }, [id, onDelete])

  const handleRotate = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    // Rotate by 15 degrees on each click, shift+click for 90 degrees
    const rotationStep = e.shiftKey ? 90 : 15
    const newRotation = (rotation + rotationStep) % 360
    onUpdate(id, { rotation: newRotation })
  }, [id, rotation, onUpdate])

  const handleFlipHorizontal = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onUpdate(id, { flipHorizontal: !flipHorizontal })
  }, [id, flipHorizontal, onUpdate])

  const handleFlipVertical = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onUpdate(id, { flipVertical: !flipVertical })
  }, [id, flipVertical, onUpdate])

  return (
    <ImageContainer
      selected={selected}
      zoom={zoom}
      style={{
        left: position.x,
        top: position.y,
        width: size.width,
        height: size.height,
        cursor: isDragging ? 'grabbing' : isResizing ? 'nwse-resize' : 'grab',
        boxShadow: selected ? '0 8px 16px rgba(0,0,0,0.15)' : '0 2px 4px rgba(0,0,0,0.1)',
      }}
      onMouseDown={handleMouseDown}
    >
      <Box
        sx={{
          width: '100%',
          height: '100%',
          transform: `
            rotate(${rotation}deg) 
            scaleX(${flipHorizontal ? -1 : 1}) 
            scaleY(${flipVertical ? -1 : 1})
          `,
          transformOrigin: 'center',
          transition: 'transform 0.2s ease-in-out',
        }}
      >
        <StyledImage src={imageUrl} alt="Story image" draggable={false} />
      </Box>
      
      {!isReadOnly && (
        <>
          {/* Control buttons */}
          <Box className="image-controls">
            <Tooltip title="Rotate (Shift+click for 90°)">
              <IconButton
                size="small"
                onClick={handleRotate}
                sx={{ 
                  color: 'white',
                  padding: 0.5,
                  '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.2)' }
                }}
              >
                <RotateIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            
            <Tooltip title="Flip Horizontal">
              <IconButton
                size="small"
                onClick={handleFlipHorizontal}
                sx={{ 
                  color: 'white',
                  padding: 0.5,
                  '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.2)' }
                }}
              >
                <FlipHorizontalIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            
            <Tooltip title="Flip Vertical">
              <IconButton
                size="small"
                onClick={handleFlipVertical}
                sx={{ 
                  color: 'white',
                  padding: 0.5,
                  '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.2)' }
                }}
              >
                <FlipVerticalIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            
            <Tooltip title="Delete">
              <IconButton
                size="small"
                onClick={handleDelete}
                sx={{ 
                  color: 'white',
                  padding: 0.5,
                  '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.2)' }
                }}
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>

          {/* Resize handle */}
          <Box 
            className="resize-handle"
            onMouseDown={handleResizeMouseDown}
          >
            <ResizeIcon sx={{ fontSize: 12, color: 'white' }} />
          </Box>
        </>
      )}
    </ImageContainer>
  )
}