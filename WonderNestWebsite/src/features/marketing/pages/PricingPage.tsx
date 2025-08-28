import React, { useState } from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Switch,
  FormControlLabel,
  Stack,
  Chip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  useTheme,
} from '@mui/material'
import { ExpandMore as ExpandMoreIcon } from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'

import { PricingCard } from '../../../components/marketing/PricingCard'

export const PricingPage: React.FC = () => {
  const theme = useTheme()
  const navigate = useNavigate()
  const [isAnnual, setIsAnnual] = useState(false)

  const handlePlanSelect = (plan: string) => {
    navigate('/app/signup', { state: { selectedPlan: plan } })
  }

  const pricingPlans = [
    {
      title: 'Starter',
      price: isAnnual ? '9' : '12',
      originalPrice: isAnnual ? '15' : undefined,
      period: isAnnual ? 'month' : 'month',
      description: 'Perfect for families with one child just getting started',
      features: [
        '1 child profile',
        '10 educational games',
        '5 story adventures',
        'Basic progress tracking',
        'Parental controls',
        'Safe content filtering',
        'Email support',
      ],
      buttonText: 'Start Free Trial',
      badge: '14-day free trial',
    },
    {
      title: 'Family',
      price: isAnnual ? '19' : '25',
      originalPrice: isAnnual ? '30' : undefined,
      period: isAnnual ? 'month' : 'month',
      description: 'Ideal for families with multiple children and comprehensive learning',
      features: [
        'Up to 4 child profiles',
        '50+ educational games',
        '20+ story adventures',
        'Advanced progress tracking',
        'Family challenges',
        'Custom content recommendations',
        'Priority email & chat support',
        'Offline content download',
      ],
      isPopular: true,
      buttonText: 'Start Free Trial',
      badge: 'Most Popular',
    },
    {
      title: 'Premium',
      price: isAnnual ? '35' : '45',
      originalPrice: isAnnual ? '54' : undefined,
      period: isAnnual ? 'month' : 'month',
      description: 'Complete solution for families and educators who want everything',
      features: [
        'Unlimited child profiles',
        'All educational games & content',
        'Unlimited story creation',
        'Advanced analytics dashboard',
        'Custom learning paths',
        'Video calls with educational consultants',
        '24/7 priority support',
        'Early access to new features',
        'Bulk family account management',
      ],
      buttonText: 'Start Free Trial',
      badge: 'Complete Solution',
    },
  ]

  const faqItems = [
    {
      question: 'Is there really a free trial?',
      answer: 'Yes! All plans include a 14-day free trial with full access to all features. No credit card required to start, and you can cancel anytime during the trial period.',
    },
    {
      question: 'How does the child profile system work?',
      answer: 'Each child gets their own personalized profile with age-appropriate content, individual progress tracking, and customized learning paths. Parents can easily switch between profiles and manage all children from one dashboard.',
    },
    {
      question: 'What happens if I exceed my plan limits?',
      answer: 'If you need more child profiles, you\'ll receive a notification and can easily upgrade your plan. There are no overage fees, and we\'ll work with you to find the best solution for your family.',
    },
    {
      question: 'Is WonderNest really COPPA compliant?',
      answer: 'Absolutely. We are fully COPPA compliant and take child privacy seriously. We don\'t collect unnecessary personal information, don\'t show ads, and don\'t share data with third parties. Parents have full control over their child\'s data.',
    },
    {
      question: 'Can I change or cancel my subscription anytime?',
      answer: 'Yes, you can upgrade, downgrade, or cancel your subscription at any time. There are no long-term contracts or cancellation fees. If you cancel, you\'ll still have access until your current billing period ends.',
    },
    {
      question: 'What payment methods do you accept?',
      answer: 'We accept all major credit cards (Visa, MasterCard, American Express, Discover) and PayPal. All payments are processed securely, and we don\'t store your payment information on our servers.',
    },
    {
      question: 'Do you offer discounts for educators or multiple families?',
      answer: 'Yes! We offer special pricing for educators, schools, and family groups. Contact our support team for information about bulk discounts and educational institution pricing.',
    },
    {
      question: 'What if my child outgrows the content?',
      answer: 'Our content is designed for ages 3-12 with adaptive difficulty levels. As your child grows, the content automatically adjusts to their skill level. We also regularly add new games and stories for older children.',
    },
  ]

  return (
    <Box>
      {/* Header */}
      <Box sx={{ pt: 8, pb: 4, textAlign: 'center' }}>
        <Container maxWidth="lg">
          <Typography className="section-title" variant="h2" component="h1">
            Choose the Perfect Plan for Your Family
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            All plans include a 14-day free trial with full access to features
          </Typography>

          {/* Annual/Monthly Toggle */}
          <Box sx={{ mt: 4, mb: 2 }}>
            <FormControlLabel
              control={
                <Switch
                  checked={isAnnual}
                  onChange={(e) => setIsAnnual(e.target.checked)}
                  color="primary"
                />
              }
              label={
                <Stack direction="row" alignItems="center" spacing={1}>
                  <Typography variant="body1">Pay Annually</Typography>
                  <Chip 
                    label="Save 25%" 
                    size="small" 
                    color="secondary"
                    sx={{ fontWeight: 600 }}
                  />
                </Stack>
              }
              sx={{ 
                '& .MuiFormControlLabel-label': {
                  fontSize: '1.1rem',
                  fontWeight: 500,
                },
              }}
            />
          </Box>
        </Container>
      </Box>

      {/* Pricing Cards */}
      <Container maxWidth="lg" sx={{ pb: 8 }}>
        <Grid container spacing={4} justifyContent="center">
          {pricingPlans.map((plan, index) => (
            <Grid item xs={12} md={4} key={index}>
              <PricingCard
                {...plan}
                onSelect={() => handlePlanSelect(plan.title.toLowerCase())}
              />
            </Grid>
          ))}
        </Grid>

        {/* Additional Info */}
        <Box sx={{ textAlign: 'center', mt: 6, p: 4, bgcolor: 'background.paper', borderRadius: 2 }}>
          <Typography variant="h6" fontWeight={600} color="primary" gutterBottom>
            All Plans Include
          </Typography>
          <Grid container spacing={2} sx={{ mt: 2 }}>
            {[
              'COPPA-compliant safety',
              'No ads or third-party tracking',
              'Offline content access',
              'Cross-platform compatibility',
              'Regular content updates',
              'Family sharing features',
            ].map((feature, index) => (
              <Grid item xs={12} sm={6} md={4} key={index}>
                <Typography
                  variant="body2"
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    '&:before': {
                      content: '"✓"',
                      color: theme.palette.secondary.main,
                      fontWeight: 'bold',
                      marginRight: 1,
                    },
                  }}
                >
                  {feature}
                </Typography>
              </Grid>
            ))}
          </Grid>
        </Box>
      </Container>

      {/* FAQ Section */}
      <Box sx={{ 
        background: `linear-gradient(135deg, ${theme.palette.primary.main}05 0%, ${theme.palette.secondary.main}05 100%)`,
        py: 8 
      }}>
        <Container maxWidth="md">
          <Typography className="section-title" variant="h3" component="h2" sx={{ mb: 4 }}>
            Frequently Asked Questions
          </Typography>

          {faqItems.map((faq, index) => (
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
      </Box>

      {/* Final CTA */}
      <Box sx={{ py: 8, textAlign: 'center' }}>
        <Container maxWidth="sm">
          <Typography variant="h4" fontWeight={600} color="primary" gutterBottom>
            Still Have Questions?
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
            Our family success team is here to help you choose the right plan and get started with WonderNest.
          </Typography>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} justifyContent="center">
            <Typography
              component="a"
              href="/contact"
              sx={{
                color: theme.palette.primary.main,
                textDecoration: 'none',
                fontWeight: 600,
                '&:hover': { textDecoration: 'underline' },
              }}
            >
              Contact Our Team →
            </Typography>
            <Typography
              component="a"
              href="/app/signup"
              sx={{
                color: theme.palette.secondary.main,
                textDecoration: 'none',
                fontWeight: 600,
                '&:hover': { textDecoration: 'underline' },
              }}
            >
              Start Your Free Trial →
            </Typography>
          </Stack>
        </Container>
      </Box>
    </Box>
  )
}