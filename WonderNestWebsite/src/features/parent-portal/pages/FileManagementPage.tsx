import React, { useState } from 'react'
import { Box, Container, Typography, Tab, Tabs, Paper, IconButton } from '@mui/material'
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import FileManager from '@/components/common/FileManager'
import { LogoutButton } from '@/components/common/LogoutButton'

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`file-tabpanel-${index}`}
      aria-labelledby={`file-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  )
}

export const FileManagementPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0)
  const navigate = useNavigate()

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue)
  }

  const categories = [
    { label: 'All Files', value: undefined },
    { label: 'Profile Pictures', value: 'profile_picture' },
    { label: 'Content', value: 'content' },
    { label: 'Documents', value: 'document' },
    { label: 'Game Assets', value: 'game_asset' },
    { label: 'Artwork', value: 'artwork' },
  ]

  return (
    <Container maxWidth="xl">
      <Box sx={{ py: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
          <IconButton 
            onClick={() => navigate('/app/parent')}
            sx={{ mr: 1 }}
          >
            <ArrowBackIcon />
          </IconButton>
          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="h4" component="h1" gutterBottom>
              File Management
            </Typography>
          </Box>
          <LogoutButton variant="icon" />
        </Box>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
          Upload and manage files for your family. Files can be categorized and associated with specific children.
        </Typography>

        <Paper sx={{ width: '100%' }}>
          <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
            <Tabs
              value={activeTab}
              onChange={handleTabChange}
              aria-label="file category tabs"
              variant="scrollable"
              scrollButtons="auto"
            >
              {categories.map((category, index) => (
                <Tab
                  key={index}
                  label={category.label}
                  id={`file-tab-${index}`}
                  aria-controls={`file-tabpanel-${index}`}
                />
              ))}
            </Tabs>
          </Box>

          {categories.map((category, index) => (
            <TabPanel key={index} value={activeTab} index={index}>
              <FileManager
                category={category.value as any}
                showUpload={true}
              />
            </TabPanel>
          ))}
        </Paper>
      </Box>
    </Container>
  )
}

export default FileManagementPage