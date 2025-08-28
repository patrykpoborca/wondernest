import React from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  Stack,
  Chip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Alert,
  useTheme,
} from '@mui/material'
import {
  Shield as ShieldIcon,
  Lock as LockIcon,
  Visibility as VisibilityIcon,
  Block as BlockIcon,
  VerifiedUser as VerifiedIcon,
  FamilyRestroom as FamilyIcon,
  Gavel as ComplianceIcon,
  Security as SecurityIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material'

export const SafetyPage: React.FC = () => {
  const theme = useTheme()

  const safetyFeatures = [
    {
      icon: <ComplianceIcon sx={{ fontSize: '3rem' }} />,
      title: 'COPPA Compliance',
      description: 'Full compliance with the Children\'s Online Privacy Protection Act, ensuring your child\'s data is protected according to federal standards.',
      details: [
        'No personal information collected without parental consent',
        'Age verification required for all accounts',
        'Transparent data collection and usage policies',
        'Regular compliance audits and certifications',
      ],
    },
    {
      icon: <LockIcon sx={{ fontSize: '3rem' }} />,
      title: 'Data Encryption',
      description: 'All data is encrypted both in transit and at rest using industry-standard encryption protocols.',
      details: [
        'AES-256 encryption for stored data',
        'TLS 1.3 for data transmission',
        'Secure key management systems',
        'Regular security vulnerability assessments',
      ],
    },
    {
      icon: <BlockIcon sx={{ fontSize: '3rem' }} />,
      title: 'Content Filtering',
      description: 'Advanced content moderation systems ensure all content is age-appropriate and safe for children.',
      details: [
        'AI-powered content screening',
        'Human moderation review',
        'Community reporting systems',
        'Regularly updated safety filters',
      ],
    },
    {
      icon: <VisibilityIcon sx={{ fontSize: '3rem' }} />,
      title: 'Parental Controls',
      description: 'Comprehensive tools for parents to monitor, control, and customize their child\'s experience.',
      details: [
        'Real-time activity monitoring',
        'Screen time limits and schedules',
        'Content approval workflows',
        'Communication and contact controls',
      ],
    },
    {
      icon: <FamilyIcon sx={{ fontSize: '3rem' }} />,
      title: 'Family Privacy',
      description: 'Strong privacy protections that keep your family\'s information secure and private.',
      details: [
        'No third-party data sharing',
        'No targeted advertising',
        'Minimal data collection practices',
        'Right to data deletion',
      ],
    },
    {
      icon: <VerifiedIcon sx={{ fontSize: '3rem' }} />,
      title: 'Verified Environment',
      description: 'Safe, verified community spaces where children can learn and interact appropriately.',
      details: [
        'Identity verification for all users',
        'Moderated community interactions',
        'Safe communication tools',
        'Zero-tolerance policy for inappropriate content',
      ],
    },
  ]

  const coppaFaqs = [
    {
      question: 'What is COPPA and why is it important?',
      answer: 'The Children\'s Online Privacy Protection Act (COPPA) is a federal law that protects the privacy of children under 13 online. It requires websites and online services to obtain parental consent before collecting personal information from children. WonderNest is fully COPPA compliant, meaning we follow strict guidelines to protect your child\'s privacy and give you control over their data.',
    },
    {
      question: 'What information does WonderNest collect from children?',
      answer: 'WonderNest collects only the minimum information necessary to provide our educational services. This includes a child\'s first name (or nickname), age range, and learning progress data. We do not collect last names, addresses, phone numbers, or other personal identifiers without explicit parental consent. All data collection is transparent and serves educational purposes only.',
    },
    {
      question: 'How does parental consent work?',
      answer: 'Parents must create and verify their own account before adding any child profiles. All child activities require parental approval, and parents can review and delete any data at any time. We use a double opt-in system for consent and provide clear information about what data we collect and how it\'s used.',
    },
    {
      question: 'Can my child communicate with other users?',
      answer: 'WonderNest provides very limited, heavily moderated communication features. Children cannot share personal information or communicate freely with others. Any communication is pre-filtered, reviewed by our moderation team, and restricted to educational content sharing within approved family groups.',
    },
    {
      question: 'How can I control my child\'s experience?',
      answer: 'Parents have complete control through our comprehensive parental dashboard. You can monitor all activities, set screen time limits, approve or restrict content, manage communication settings, and review your child\'s learning progress. You can also delete your child\'s account and all associated data at any time.',
    },
    {
      question: 'What happens to my child\'s data?',
      answer: 'Your child\'s data is used solely to provide educational services and track learning progress. We never sell, rent, or share personal information with third parties for marketing purposes. Data is stored securely and can be deleted at your request. When a child reaches 13, parents can choose to maintain the account or delete all data.',
    },
  ]

  const certifications = [
    {
      name: 'COPPA Compliant',
      description: 'Federal Trade Commission certified compliance with children\'s privacy laws',
      color: theme.palette.success.main,
    },
    {
      name: 'SOC 2 Type II',
      description: 'Audited security controls and data protection practices',
      color: theme.palette.primary.main,
    },
    {
      name: 'GDPR Compliant',
      description: 'European data protection regulation compliance for global families',
      color: theme.palette.info.main,
    },
    {
      name: 'ISO 27001',
      description: 'International standard for information security management',
      color: theme.palette.warning.main,
    },
  ]

  return (
    <Box>
      {/* Header */}
      <Box
        sx={{
          pt: 8,
          pb: 6,
          background: `linear-gradient(135deg, ${theme.palette.success.main}15 0%, ${theme.palette.primary.main}10 100%)`,
        }}
      >
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <ShieldIcon sx={{ fontSize: '4rem', color: theme.palette.success.main, mb: 2 }} />
            <Typography className="section-title" variant="h2" component="h1">
              Your Child's Safety is Our Priority
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Comprehensive protection with COPPA compliance, advanced security, and complete parental control
            </Typography>
          </Box>

          {/* Trust Indicators */}
          <Stack direction="row" spacing={2} justifyContent="center" flexWrap="wrap">
            {certifications.map((cert, index) => (
              <Chip
                key={index}
                icon={<VerifiedIcon />}
                label={cert.name}
                sx={{
                  backgroundColor: `${cert.color}15`,
                  color: cert.color,
                  fontWeight: 600,
                  padding: '8px 4px',
                  '& .MuiChip-icon': {
                    color: cert.color,
                  },
                }}
              />
            ))}
          </Stack>
        </Container>
      </Box>

      {/* COPPA Alert */}
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Alert
          severity="info"
          icon={<ShieldIcon />}
          sx={{
            bgcolor: `${theme.palette.primary.main}08`,
            border: `1px solid ${theme.palette.primary.main}`,
            borderRadius: 2,
            '& .MuiAlert-message': {
              fontSize: '1rem',
            },
          }}
        >
          <Typography variant="h6" fontWeight={600} gutterBottom>
            COPPA Compliance Guarantee
          </Typography>
          WonderNest is fully compliant with the Children's Online Privacy Protection Act (COPPA). 
          We are committed to protecting your child's privacy and giving you complete control over their digital experience.
        </Alert>
      </Container>

      {/* Safety Features */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            Comprehensive Safety Features
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Multiple layers of protection to ensure a safe learning environment
          </Typography>
        </Box>

        <Grid container spacing={4}>
          {safetyFeatures.map((feature, index) => (
            <Grid item xs={12} md={6} key={index}>
              <Card
                sx={{
                  height: '100%',
                  p: 3,
                  border: `1px solid ${theme.palette.divider}`,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: theme.shadows[8],
                    borderColor: theme.palette.success.main,
                  },
                }}
              >
                <Stack spacing={3}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Box sx={{ color: theme.palette.success.main }}>
                      {feature.icon}
                    </Box>
                    <Typography variant="h5" fontWeight={600} color="primary">
                      {feature.title}
                    </Typography>
                  </Box>

                  <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.6 }}>
                    {feature.description}
                  </Typography>

                  <Box>
                    {feature.details.map((detail, detailIndex) => (
                      <Typography
                        key={detailIndex}
                        variant="body2"
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          mb: 1,
                          color: 'text.secondary',
                          '&:before': {
                            content: '"✓"',
                            color: theme.palette.success.main,
                            fontWeight: 'bold',
                            marginRight: 1,
                            fontSize: '1rem',
                          },
                        }}
                      >
                        {detail}
                      </Typography>
                    ))}
                  </Box>
                </Stack>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Certifications */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h3" component="h2">
              Security Certifications
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Independently verified security and compliance standards
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {certifications.map((cert, index) => (
              <Grid item xs={12} sm={6} md={3} key={index}>
                <Card
                  sx={{
                    height: '100%',
                    textAlign: 'center',
                    p: 3,
                    border: `2px solid ${cert.color}`,
                    bgcolor: `${cert.color}05`,
                  }}
                >
                  <SecurityIcon sx={{ fontSize: '3rem', color: cert.color, mb: 2 }} />
                  <Typography variant="h6" fontWeight={600} color={cert.color} gutterBottom>
                    {cert.name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {cert.description}
                  </Typography>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* COPPA FAQ */}
      <Container maxWidth="md" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            COPPA & Privacy FAQ
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Common questions about child privacy and data protection
          </Typography>
        </Box>

        {coppaFaqs.map((faq, index) => (
          <Accordion
            key={index}
            sx={{
              mb: 1,
              boxShadow: 'none',
              border: `1px solid ${theme.palette.divider}`,
              '&:before': { display: 'none' },
              borderRadius: '8px !important',
            }}
          >
            <AccordionSummary
              expandIcon={<ExpandMoreIcon />}
              sx={{
                '& .MuiAccordionSummary-content': {
                  margin: '16px 0',
                },
              }}
            >
              <Typography variant="h6" fontWeight={600}>
                {faq.question}
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.7 }}>
                {faq.answer}
              </Typography>
            </AccordionDetails>
          </Accordion>
        ))}
      </Container>

      {/* Contact for Security */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <Typography variant="h4" fontWeight={600} color="primary" gutterBottom>
            Questions About Safety?
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4, lineHeight: 1.6 }}>
            Our security team is available to answer any questions about child safety, 
            data protection, or COPPA compliance. We believe transparency is essential 
            for building trust with families.
          </Typography>
          <Stack spacing={2}>
            <Typography variant="body1">
              📧 Email: <strong>security@wondernest.com</strong>
            </Typography>
            <Typography variant="body1">
              🔒 Security Reports: <strong>security-reports@wondernest.com</strong>
            </Typography>
            <Typography variant="body1">
              👨‍👩‍👧‍👦 Parent Support: <strong>parents@wondernest.com</strong>
            </Typography>
          </Stack>
        </Container>
      </Box>
    </Box>
  )
}