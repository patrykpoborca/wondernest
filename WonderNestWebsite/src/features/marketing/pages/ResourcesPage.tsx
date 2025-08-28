import React from 'react'
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Chip,
  Stack,
  Avatar,
  useTheme,
} from '@mui/material'
import {
  Article as ArticleIcon,
  Schedule as TimeIcon,
  Person as AuthorIcon,
  LocalLibrary as LibraryIcon,
  Psychology as DevIcon,
  Security as SafetyIcon,
  School as EducationIcon,
} from '@mui/icons-material'

export const ResourcesPage: React.FC = () => {
  const theme = useTheme()

  const featuredArticles = [
    {
      title: 'Digital Safety for Young Children: A Parent\'s Complete Guide',
      excerpt: 'Learn how to create safe digital learning environments for children aged 3-12, including screen time management, content filtering, and healthy digital habits.',
      author: 'Dr. Sarah Mitchell',
      authorRole: 'Child Development Expert',
      publishDate: 'March 15, 2024',
      readTime: '8 min read',
      category: 'Safety',
      categoryColor: theme.palette.success.main,
      image: '/api/placeholder/400/250',
    },
    {
      title: 'Understanding Your Child\'s Learning Style in the Digital Age',
      excerpt: 'Discover how to identify your child\'s unique learning preferences and choose digital tools that support their individual development needs.',
      author: 'Jennifer Rodriguez',
      authorRole: 'Learning Sciences Researcher',
      publishDate: 'March 10, 2024',
      readTime: '6 min read',
      category: 'Development',
      categoryColor: theme.palette.primary.main,
      image: '/api/placeholder/400/250',
    },
    {
      title: 'Building Family Screen Time Rules That Actually Work',
      excerpt: 'Practical strategies for creating and maintaining healthy screen time boundaries that support both learning and family connection.',
      author: 'Michael Chen',
      authorRole: 'Parent & Technology Expert',
      publishDate: 'March 5, 2024',
      readTime: '5 min read',
      category: 'Parenting',
      categoryColor: theme.palette.warning.main,
      image: '/api/placeholder/400/250',
    },
  ]

  const resourceCategories = [
    {
      title: 'Child Development',
      icon: <DevIcon sx={{ fontSize: '3rem' }} />,
      description: 'Understanding milestones, learning stages, and supporting your child\'s growth',
      articleCount: 12,
      color: theme.palette.primary.main,
    },
    {
      title: 'Digital Safety',
      icon: <SafetyIcon sx={{ fontSize: '3rem' }} />,
      description: 'Protecting children online, privacy settings, and safe digital habits',
      articleCount: 8,
      color: theme.palette.success.main,
    },
    {
      title: 'Educational Technology',
      icon: <EducationIcon sx={{ fontSize: '3rem' }} />,
      description: 'Choosing the right digital learning tools and maximizing their benefits',
      articleCount: 15,
      color: theme.palette.info.main,
    },
    {
      title: 'Parenting Tips',
      icon: <LibraryIcon sx={{ fontSize: '3rem' }} />,
      description: 'Practical advice for navigating modern parenting challenges',
      articleCount: 20,
      color: theme.palette.warning.main,
    },
  ]

  const recentArticles = [
    {
      title: 'COPPA Compliance: What Every Parent Should Know',
      excerpt: 'Understanding your rights and how to protect your child\'s privacy online.',
      readTime: '4 min read',
      category: 'Safety',
    },
    {
      title: 'Age-Appropriate Content: Guidelines by Development Stage',
      excerpt: 'Matching digital content to your child\'s developmental needs and abilities.',
      readTime: '7 min read',
      category: 'Development',
    },
    {
      title: 'Creating Learning Rituals That Include Technology',
      excerpt: 'Integrating digital tools into daily learning routines and family time.',
      readTime: '5 min read',
      category: 'Parenting',
    },
    {
      title: 'Signs Your Child Is Ready for More Advanced Content',
      excerpt: 'Recognizing when to introduce new challenges and learning opportunities.',
      readTime: '6 min read',
      category: 'Development',
    },
  ]

  const getCategoryColor = (category: string) => {
    const colorMap: { [key: string]: string } = {
      'Safety': theme.palette.success.main,
      'Development': theme.palette.primary.main,
      'Parenting': theme.palette.warning.main,
      'Education': theme.palette.info.main,
    }
    return colorMap[category] || theme.palette.grey[500]
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
              Resources for Families
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Expert guidance on child development, digital safety, and creating positive learning experiences
            </Typography>
          </Box>
        </Container>
      </Box>

      {/* Featured Articles */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            Featured Articles
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            In-depth guides from our experts and partners
          </Typography>
        </Box>

        <Grid container spacing={4}>
          {featuredArticles.map((article, index) => (
            <Grid item xs={12} md={4} key={index}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: theme.shadows[8],
                  },
                }}
              >
                {/* Article Image */}
                <Box
                  sx={{
                    height: 200,
                    background: `linear-gradient(135deg, ${article.categoryColor}15 0%, ${article.categoryColor}05 100%)`,
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    position: 'relative',
                  }}
                >
                  <ArticleIcon sx={{ fontSize: '4rem', color: article.categoryColor, opacity: 0.6 }} />
                  <Chip
                    label={article.category}
                    size="small"
                    sx={{
                      position: 'absolute',
                      top: 12,
                      left: 12,
                      backgroundColor: article.categoryColor,
                      color: 'white',
                      fontWeight: 600,
                    }}
                  />
                </Box>

                <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
                  <Typography variant="h6" fontWeight={600} gutterBottom sx={{ lineHeight: 1.3 }}>
                    {article.title}
                  </Typography>

                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2, flexGrow: 1 }}>
                    {article.excerpt}
                  </Typography>

                  {/* Author and Meta */}
                  <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 2 }}>
                    <Avatar sx={{ width: 32, height: 32, bgcolor: article.categoryColor }}>
                      <AuthorIcon sx={{ fontSize: '1rem' }} />
                    </Avatar>
                    <Box>
                      <Typography variant="body2" fontWeight={600}>
                        {article.author}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {article.authorRole}
                      </Typography>
                    </Box>
                  </Stack>

                  <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                    <Stack direction="row" alignItems="center" spacing={1}>
                      <TimeIcon sx={{ fontSize: '0.875rem', color: 'text.secondary' }} />
                      <Typography variant="caption" color="text.secondary">
                        {article.readTime}
                      </Typography>
                    </Stack>
                    <Typography variant="caption" color="text.secondary">
                      {article.publishDate}
                    </Typography>
                  </Stack>

                  <Button variant="outlined" color="primary" size="small">
                    Read Article
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Resource Categories */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography className="section-title" variant="h3" component="h2">
              Browse by Topic
            </Typography>
            <Typography className="section-subtitle" variant="h6">
              Find resources organized by your interests and needs
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {resourceCategories.map((category, index) => (
              <Grid item xs={12} sm={6} md={3} key={index}>
                <Card
                  sx={{
                    height: '100%',
                    p: 3,
                    textAlign: 'center',
                    border: `1px solid ${category.color}30`,
                    transition: 'all 0.3s ease',
                    cursor: 'pointer',
                    '&:hover': {
                      transform: 'translateY(-4px)',
                      boxShadow: theme.shadows[8],
                      borderColor: category.color,
                    },
                  }}
                >
                  <Box sx={{ color: category.color, mb: 2 }}>
                    {category.icon}
                  </Box>
                  
                  <Typography variant="h6" fontWeight={600} gutterBottom>
                    {category.title}
                  </Typography>
                  
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {category.description}
                  </Typography>

                  <Chip
                    label={`${category.articleCount} articles`}
                    size="small"
                    sx={{
                      backgroundColor: `${category.color}15`,
                      color: category.color,
                      fontWeight: 500,
                    }}
                  />
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Recent Articles */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Box sx={{ textAlign: 'center', mb: 6 }}>
          <Typography className="section-title" variant="h3" component="h2">
            Recent Articles
          </Typography>
          <Typography className="section-subtitle" variant="h6">
            Stay up-to-date with our latest insights and tips
          </Typography>
        </Box>

        <Grid container spacing={3}>
          {recentArticles.map((article, index) => (
            <Grid item xs={12} sm={6} key={index}>
              <Card
                sx={{
                  p: 3,
                  border: `1px solid ${theme.palette.divider}`,
                  transition: 'all 0.3s ease',
                  cursor: 'pointer',
                  '&:hover': {
                    transform: 'translateY(-2px)',
                    boxShadow: theme.shadows[4],
                    borderColor: getCategoryColor(article.category),
                  },
                }}
              >
                <Stack direction="row" spacing={2} alignItems="flex-start">
                  <Box
                    sx={{
                      width: 60,
                      height: 60,
                      borderRadius: 2,
                      background: `linear-gradient(135deg, ${getCategoryColor(article.category)}15 0%, ${getCategoryColor(article.category)}05 100%)`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}
                  >
                    <ArticleIcon sx={{ color: getCategoryColor(article.category), fontSize: '1.5rem' }} />
                  </Box>

                  <Box sx={{ flexGrow: 1 }}>
                    <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 1 }}>
                      <Chip
                        label={article.category}
                        size="small"
                        sx={{
                          backgroundColor: `${getCategoryColor(article.category)}15`,
                          color: getCategoryColor(article.category),
                          fontWeight: 500,
                        }}
                      />
                      <Typography variant="caption" color="text.secondary">
                        {article.readTime}
                      </Typography>
                    </Stack>

                    <Typography variant="h6" fontWeight={600} gutterBottom sx={{ lineHeight: 1.3 }}>
                      {article.title}
                    </Typography>

                    <Typography variant="body2" color="text.secondary">
                      {article.excerpt}
                    </Typography>
                  </Box>
                </Stack>
              </Card>
            </Grid>
          ))}
        </Grid>

        <Box sx={{ textAlign: 'center', mt: 6 }}>
          <Button variant="outlined" size="large" color="primary">
            View All Articles
          </Button>
        </Box>
      </Container>

      {/* Newsletter Signup */}
      <Box sx={{ bgcolor: 'background.default', py: 8 }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <Typography variant="h4" fontWeight={600} color="primary" gutterBottom>
            Stay Updated
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
            Get the latest parenting tips, safety updates, and educational insights delivered to your inbox monthly.
          </Typography>
          
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} justifyContent="center">
            <Button variant="contained" size="large" color="primary">
              Subscribe to Newsletter
            </Button>
            <Button variant="outlined" size="large">
              Follow Our Blog
            </Button>
          </Stack>
          
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            ✓ Weekly tips ✓ Safety updates ✓ New resource alerts ✓ Unsubscribe anytime
          </Typography>
        </Container>
      </Box>
    </Box>
  )
}