import React, { useState } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Paper,
  Avatar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Divider
} from '@mui/material'
import {
  CloudUpload,
  Publish,
  FileUpload,
  CheckCircle,
  Error,
  Info
} from '@mui/icons-material'

import { adminApiService } from '@/services/adminApi'
import { BulkUploadResult, BulkPublishResult } from '@/types/admin'

interface BulkOperationsProps {
  open: boolean
  onClose: () => void
  onSuccess: () => void
  selectedContentIds?: string[]
}

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => (
  <div hidden={value !== index}>
    {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
  </div>
)

export const BulkOperations: React.FC<BulkOperationsProps> = ({
  open,
  onClose,
  onSuccess,
  selectedContentIds = []
}) => {
  const [activeTab, setActiveTab] = useState(0)
  const [csvFile, setCsvFile] = useState<File | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [bulkUploadResult, setBulkUploadResult] = useState<BulkUploadResult | null>(null)
  const [bulkPublishResult, setBulkPublishResult] = useState<BulkPublishResult | null>(null)

  const handleClose = () => {
    if (!loading) {
      onClose()
      // Reset state
      setActiveTab(0)
      setCsvFile(null)
      setError(null)
      setBulkUploadResult(null)
      setBulkPublishResult(null)
    }
  }

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue)
    setError(null)
  }

  const handleCsvFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setCsvFile(file)
      setError(null)
      setBulkUploadResult(null)
    }
  }

  const handleBulkUpload = async () => {
    if (!csvFile) {
      setError('Please select a CSV file')
      return
    }

    try {
      setLoading(true)
      setError(null)
      
      const formData = new FormData()
      formData.append('csv_file', csvFile)
      
      const result = await adminApiService.bulkUploadCSV(formData)
      setBulkUploadResult(result)
      
      if (result.success_count > 0) {
        onSuccess()
      }
    } catch (err: any) {
      setError(err.error || 'Failed to process bulk upload')
    } finally {
      setLoading(false)
    }
  }

  const handleBulkPublish = async () => {
    if (selectedContentIds.length === 0) {
      setError('No content selected for publishing')
      return
    }

    try {
      setLoading(true)
      setError(null)
      
      const result = await adminApiService.bulkPublishContent(selectedContentIds)
      setBulkPublishResult(result)
      
      if (result.success_count > 0) {
        onSuccess()
      }
    } catch (err: any) {
      setError(err.error || 'Failed to publish content')
    } finally {
      setLoading(false)
    }
  }

  const formatFileSize = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(1024))
    return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${sizes[i]}`
  }

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2, maxHeight: '90vh' }
      }}
    >
      <DialogTitle>
        <Typography variant="h6" fontWeight={600}>
          Bulk Operations
        </Typography>
        <Typography variant="body2" color="textSecondary">
          Perform bulk actions on content and creators
        </Typography>
      </DialogTitle>

      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={activeTab} onChange={handleTabChange}>
            <Tab label="CSV Upload" icon={<FileUpload />} />
            <Tab 
              label={`Publish Selected (${selectedContentIds.length})`} 
              icon={<Publish />}
              disabled={selectedContentIds.length === 0}
            />
          </Tabs>
        </Box>

        {/* CSV Upload Tab */}
        <TabPanel value={activeTab} index={0}>
          <Box>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Bulk Content Upload via CSV
            </Typography>
            <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
              Upload multiple content items at once using a CSV file. The CSV should include columns for title, description, content_type, creator_id, and other metadata.
            </Typography>

            {/* File Upload Area */}
            <Paper 
              sx={{ 
                p: 4, 
                border: '2px dashed', 
                borderColor: csvFile ? 'success.main' : 'grey.300',
                bgcolor: csvFile ? 'success.50' : 'grey.50',
                textAlign: 'center',
                cursor: 'pointer',
                transition: 'all 0.2s',
                mb: 3
              }}
              onClick={() => document.getElementById('csv-upload')?.click()}
            >
              <input
                id="csv-upload"
                type="file"
                hidden
                accept=".csv"
                onChange={handleCsvFileChange}
              />
              <Avatar sx={{ 
                mx: 'auto', 
                mb: 2, 
                bgcolor: csvFile ? 'success.main' : 'primary.main',
                width: 60,
                height: 60
              }}>
                {csvFile ? <CheckCircle /> : <CloudUpload />}
              </Avatar>
              {csvFile ? (
                <Box>
                  <Typography variant="h6" color="success.main">
                    CSV File Selected
                  </Typography>
                  <Typography variant="body2">
                    {csvFile.name} ({formatFileSize(csvFile.size)})
                  </Typography>
                </Box>
              ) : (
                <Box>
                  <Typography variant="h6">
                    Click to Select CSV File
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Upload a CSV file with content metadata
                  </Typography>
                </Box>
              )}
            </Paper>

            {/* CSV Template Info */}
            <Alert severity="info" sx={{ mb: 3 }}>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>
                Required CSV Columns:
              </Typography>
              <Typography variant="body2">
                title, description, content_type, creator_id, tags (JSON array), age_groups (JSON array), difficulty_level, educational_objectives (JSON array), file_url
              </Typography>
            </Alert>

            {/* Upload Results */}
            {bulkUploadResult && (
              <Paper sx={{ p: 3, mt: 2 }}>
                <Typography variant="h6" sx={{ mb: 2 }}>
                  Upload Results
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 2 }}>
                  <Box sx={{ textAlign: 'center' }}>
                    <Typography variant="h4" color="success.main">
                      {bulkUploadResult.success_count}
                    </Typography>
                    <Typography variant="body2">Successful</Typography>
                  </Box>
                  <Box sx={{ textAlign: 'center' }}>
                    <Typography variant="h4" color="error.main">
                      {bulkUploadResult.error_count}
                    </Typography>
                    <Typography variant="body2">Failed</Typography>
                  </Box>
                </Box>
                
                {bulkUploadResult.errors.length > 0 && (
                  <Box>
                    <Typography variant="subtitle2" sx={{ mb: 1 }}>
                      Errors:
                    </Typography>
                    <TableContainer component={Paper} variant="outlined">
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>Row</TableCell>
                            <TableCell>Error</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {bulkUploadResult.errors.map((error, index) => (
                            <TableRow key={index}>
                              <TableCell>{error.row}</TableCell>
                              <TableCell>{error.error}</TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Box>
                )}
              </Paper>
            )}
          </Box>
        </TabPanel>

        {/* Bulk Publish Tab */}
        <TabPanel value={activeTab} index={1}>
          <Box>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Bulk Publish Content
            </Typography>
            <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
              Publish {selectedContentIds.length} selected content items to make them available to users.
            </Typography>

            {selectedContentIds.length > 0 && (
              <Paper sx={{ p: 3, mb: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Avatar sx={{ bgcolor: 'info.main' }}>
                    <Info />
                  </Avatar>
                  <Box>
                    <Typography variant="subtitle1" fontWeight={600}>
                      Ready to Publish
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      {selectedContentIds.length} content items will be published
                    </Typography>
                  </Box>
                </Box>
              </Paper>
            )}

            {/* Publish Results */}
            {bulkPublishResult && (
              <Paper sx={{ p: 3, mt: 2 }}>
                <Typography variant="h6" sx={{ mb: 2 }}>
                  Publish Results
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 2 }}>
                  <Box sx={{ textAlign: 'center' }}>
                    <Typography variant="h4" color="success.main">
                      {bulkPublishResult.success_count}
                    </Typography>
                    <Typography variant="body2">Published</Typography>
                  </Box>
                  <Box sx={{ textAlign: 'center' }}>
                    <Typography variant="h4" color="error.main">
                      {bulkPublishResult.error_count}
                    </Typography>
                    <Typography variant="body2">Failed</Typography>
                  </Box>
                </Box>
                
                {bulkPublishResult.errors.length > 0 && (
                  <Box>
                    <Typography variant="subtitle2" sx={{ mb: 1 }}>
                      Errors:
                    </Typography>
                    <TableContainer component={Paper} variant="outlined">
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>Content ID</TableCell>
                            <TableCell>Error</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {bulkPublishResult.errors.map((error, index) => (
                            <TableRow key={index}>
                              <TableCell>{error.content_id}</TableCell>
                              <TableCell>{error.error}</TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Box>
                )}
              </Paper>
            )}
          </Box>
        </TabPanel>
      </DialogContent>

      <Divider />
      <DialogActions sx={{ p: 3 }}>
        <Button onClick={handleClose} disabled={loading}>
          {bulkUploadResult || bulkPublishResult ? 'Close' : 'Cancel'}
        </Button>
        {activeTab === 0 && !bulkUploadResult && (
          <Button
            onClick={handleBulkUpload}
            variant="contained"
            disabled={loading || !csvFile}
            startIcon={loading ? <CircularProgress size={20} /> : <CloudUpload />}
          >
            {loading ? 'Uploading...' : 'Upload CSV'}
          </Button>
        )}
        {activeTab === 1 && !bulkPublishResult && (
          <Button
            onClick={handleBulkPublish}
            variant="contained"
            disabled={loading || selectedContentIds.length === 0}
            startIcon={loading ? <CircularProgress size={20} /> : <Publish />}
          >
            {loading ? 'Publishing...' : `Publish ${selectedContentIds.length} Items`}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  )
}