import React, { useState } from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  TextField,
  Button,
  Stack,
  Chip,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  useTheme,
} from '@mui/material'
import {
  Email as EmailIcon,
  LocationOn as LocationIcon,
  QuestionAnswer as SupportIcon,
  Security as SecurityIcon,
  Business as BusinessIcon,
  School as EducationIcon,
  Send as SendIcon,
} from '@mui/icons-material'

export const ContactPage: React.FC = () => {
  const theme = useTheme()
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    category: '',
    message: '',
  })
  const [submitted, setSubmitted] = useState(false)

  const contactMethods = [
    {
      icon: <SupportIcon sx={{ fontSize: '3rem' }} />,
      title: 'General Support',
      description: 'Questions about using WonderNest, technical issues, or account help',
      contact: 'support@wondernest.com',
      responseTime: 'Within 24 hours',
      color: theme.palette.primary.main,
    },
    {
      icon: <SecurityIcon sx={{ fontSize: '3rem' }} />,
      title: 'Safety & Privacy',
      description: 'COPPA compliance, child safety, security concerns, or privacy questions',
      contact: 'privacy@wondernest.com',
      responseTime: 'Within 12 hours',
      color: theme.palette.success.main,
    },
    {
      icon: <BusinessIcon sx={{ fontSize: '3rem' }} />,
      title: 'Partnerships',
      description: 'School partnerships, bulk licensing, or business development opportunities',
      contact: 'partnerships@wondernest.com',
      responseTime: 'Within 3 business days',
      color: theme.palette.warning.main,
    },
    {
      icon: <EducationIcon sx={{ fontSize: '3rem' }} />,
      title: 'Educators',
      description: 'Classroom use, curriculum alignment, or educational content questions',
      contact: 'educators@wondernest.com',
      responseTime: 'Within 24 hours',
      color: theme.palette.info.main,
    },
  ]

  const supportResources = [
    {
      title: 'Help Center',
      description: 'Comprehensive guides, tutorials, and frequently asked questions',
      link: '/help',
    },
    {
      title: 'Video Tutorials',
      description: 'Step-by-step video guides for parents and children',
      link: '/tutorials',
    },
    {
      title: 'Safety Guide',
      description: 'Complete guide to child safety features and parental controls',
      link: '/safety-guide',
    },
    {
      title: 'Community Forum',
      description: 'Connect with other families and share learning experiences',
      link: '/community',
    },
  ]

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    // In a real app, this would submit to an API
    setSubmitted(true)
    // Reset form after submission
    setTimeout(() => {
      setFormData({
        name: '',
        email: '',
        subject: '',
        category: '',
        message: '',
      })
      setSubmitted(false)
    }, 3000)
  }

  return (
    <Box>
      {/* Header */}
      <Box
        sx={{
          pt: 8,
          pb: 6,
          background: `linear-gradient(135deg, ${theme.palette.primary.main}10 0%, ${theme.palette.secondary.main}10 100%)`,
        }}
      >
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center' }}>
            <Typography className="section-title" variant="h2" component="h1">
              Get in Touch
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              We're here to help you and your family get the most out of WonderNest
            </Typography>
          </Box>
        </Container>
      </Box>

      {/* Contact Methods */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            How Can We Help?
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Choose the best way to reach our team
          </Typography>
        </Box>

        <Grid container spacing={4}>
          {contactMethods.map((method, index) => (
            <Grid item xs={12} md={6} key={index}>
              <Card
                sx={{
                  height: '100%',
                  p: 3,
                  border: `1px solid ${method.color}30`,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: theme.shadows[8],
                    borderColor: method.color,
                  },
                }}
              >
                <Stack spacing={3}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Box sx={{ color: method.color }}>
                      {method.icon}
                    </Box>
                    <Box>
                      <Typography variant="h5" fontWeight={600} color="primary">
                        {method.title}
                      </Typography>
                      <Chip
                        label={method.responseTime}
                        size="small"
                        sx={{
                          mt: 1,
                          backgroundColor: `${method.color}15`,
                          color: method.color,
                          fontWeight: 500,
                        }}
                      />
                    </Box>
                  </Box>

                  <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.6 }}>
                    {method.description}
                  </Typography>

                  <Box
                    sx={{
                      p: 2,
                      bgcolor: `${method.color}08`,
                      borderRadius: 2,
                      border: `1px solid ${method.color}20`,
                    }}
                  >
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Contact us at:
                    </Typography>
                    <Typography
                      variant="h6"
                      color={method.color}
                      fontWeight={600}
                      sx={{ 
                        wordBreak: 'break-word',
                        textDecoration: 'none',
                        '&:hover': { textDecoration: 'underline' },
                      }}
                      component="a"
                      href={`mailto:${method.contact}`}
                    >
                      {method.contact}
                    </Typography>
                  </Box>
                </Stack>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Contact Form */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="md">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h3" component="h2">
              Send Us a Message
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Have a specific question? Fill out the form below and we'll get back to you soon.
            </Typography>
          </Box>

          {submitted && (
            <Alert 
              severity="success" 
              sx={{ mb: 4, borderRadius: 2 }}
              icon={<SendIcon />}
            >
              <Typography variant="h6" gutterBottom>
                Message Sent Successfully!
              </Typography>
              Thank you for contacting us. We've received your message and will respond within 24 hours.
            </Alert>
          )}

          <Card sx={{ p: 4 }}>
            <form onSubmit={handleSubmit}>
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Your Name"
                    value={formData.name}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    required
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Email Address"
                    type="email"
                    value={formData.email}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    required
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>Category</InputLabel>
                    <Select
                      value={formData.category}
                      label="Category"
                      onChange={(e) => handleInputChange('category', e.target.value)}
                      required
                    >
                      <MenuItem value="general">General Support</MenuItem>
                      <MenuItem value="technical">Technical Issue</MenuItem>
                      <MenuItem value="privacy">Privacy & Safety</MenuItem>
                      <MenuItem value="billing">Billing Question</MenuItem>
                      <MenuItem value="partnership">Partnership Inquiry</MenuItem>
                      <MenuItem value="educator">Educator Support</MenuItem>
                      <MenuItem value="feedback">Feedback</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Subject"
                    value={formData.subject}
                    onChange={(e) => handleInputChange('subject', e.target.value)}
                    required
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Message"
                    multiline
                    rows={6}
                    value={formData.message}
                    onChange={(e) => handleInputChange('message', e.target.value)}
                    placeholder="Please describe your question or concern in detail..."
                    required
                  />
                </Grid>
                <Grid item xs={12}>
                  <Button
                    type="submit"
                    variant="contained"
                    size="large"
                    startIcon={<SendIcon />}
                    sx={{
                      px: 4,
                      py: 1.5,
                      borderRadius: 2,
                    }}
                  >
                    Send Message
                  </Button>
                </Grid>
              </Grid>
            </form>
          </Card>
        </Container>
      </Box>

      {/* Support Resources */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            Self-Help Resources
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Find answers quickly with our comprehensive support materials
          </Typography>
        </Box>

        <Grid container spacing={4}>
          {supportResources.map((resource, index) => (
            <Grid item xs={12} sm={6} md={3} key={index}>
              <Card
                component="a"
                href={resource.link}
                sx={{
                  height: '100%',
                  p: 3,
                  textAlign: 'center',
                  border: `1px solid ${theme.palette.divider}`,
                  transition: 'all 0.3s ease',
                  cursor: 'pointer',
                  textDecoration: 'none',
                  color: 'inherit',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: theme.shadows[8],
                    borderColor: theme.palette.primary.main,
                  },
                }}
              >
                <Typography variant="h6" fontWeight={600} color="primary" gutterBottom>
                  {resource.title}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {resource.description}
                </Typography>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Additional Contact Info */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <Typography variant="h4" fontWeight={600} color="primary" gutterBottom>
            Other Ways to Reach Us
          </Typography>
          
          <Stack spacing={3} sx={{ mt: 4 }}>
            <Box>
              <EmailIcon sx={{ fontSize: '2rem', color: theme.palette.primary.main, mb: 1 }} />
              <Typography variant="h6" gutterBottom>
                General Inquiries
              </Typography>
              <Typography variant="body1" color="text.secondary">
                hello@wondernest.com
              </Typography>
            </Box>

            <Box>
              <LocationIcon sx={{ fontSize: '2rem', color: theme.palette.primary.main, mb: 1 }} />
              <Typography variant="h6" gutterBottom>
                Our Office
              </Typography>
              <Typography variant="body1" color="text.secondary">
                123 Learning Lane<br />
                San Francisco, CA 94102<br />
                United States
              </Typography>
            </Box>
          </Stack>

          <Alert severity="info" sx={{ mt: 4, textAlign: 'left' }}>
            <Typography variant="body2">
              <strong>Response Time Commitment:</strong> We strive to respond to all inquiries within 24 hours during business days. 
              Safety and privacy concerns are prioritized and typically receive responses within 12 hours.
            </Typography>
          </Alert>
        </Container>
      </Box>
    </Box>
  )
}