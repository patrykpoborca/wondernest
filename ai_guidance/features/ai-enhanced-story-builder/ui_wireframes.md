# UI Wireframes: AI-Enhanced Story Builder

## Overall Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│ Header Bar                                                   │
│ [WonderNest Logo] [Mode Selector] [Save Status] [Profile]    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐  ┌────────────────────────────┐  ┌──────────┐ │
│  │    AI    │  │                              │  │  Story   │ │
│  │ Assistant│  │    Main Story Canvas         │  │  Pages   │ │
│  │   Panel  │  │                              │  │ Navigator│ │
│  │          │  │                              │  │          │ │
│  └──────────┘  └────────────────────────────┘  └──────────┘ │
│                                                               │
│ ┌───────────────────────────────────────────────────────────┐│
│ │                    Smart Toolbar                           ││
│ └───────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Component Specifications

### 1. Mode Selector Component

```
┌─────────────────────────────────────┐
│ ⚡ Quick  │  🏗️ Builder  │  🎯 Focus  │
└─────────────────────────────────────┘
```

**States:**
- Active mode highlighted with primary color
- Hover shows mode description tooltip
- Click transitions between modes with slide animation

**Behavior:**
- Saves current work before switching
- Adjusts UI complexity based on mode
- Remembers last used mode per user

### 2. AI Assistant Panel (Collapsible)

#### Collapsed State (Default)
```
┌──┐
│AI│
│✨│
│  │
│  │
└──┘
```

#### Expanded State
```
┌────────────────────────┐
│ AI Story Assistant  [X]│
├────────────────────────┤
│ ┌────────────────────┐ │
│ │ What would you     │ │
│ │ like help with?    │ │
│ └────────────────────┘ │
│                        │
│ Quick Actions:         │
│ ┌────────────────────┐ │
│ │ 📝 Generate Story  │ │
│ └────────────────────┘ │
│ ┌────────────────────┐ │
│ │ ✨ Enhance Text    │ │
│ └────────────────────┘ │
│ ┌────────────────────┐ │
│ │ 💡 Get Suggestions │ │
│ └────────────────────┘ │
│                        │
│ Recent Suggestions:    │
│ ┌────────────────────┐ │
│ │ • Add dialogue...  │ │
│ │ • Describe scene...│ │
│ │ • Continue with... │ │
│ └────────────────────┘ │
│                        │
│ [Settings] [History]   │
└────────────────────────┘
```

**Features:**
- Smooth slide-in animation (300ms)
- Persists between page refreshes
- Context-aware suggestions update in real-time
- Drag handle for resizing

### 3. Main Story Canvas

#### Quick Mode View
```
┌─────────────────────────────────────────────────┐
│ Story Title: [Editable Field_______________]     │
│                                                  │
│ ┌───────────────────────────────────────────┐   │
│ │ Tell me about your story...                │   │
│ │                                             │   │
│ │ [Large text input area with placeholder]   │   │
│ │                                             │   │
│ │ Or choose a template:                      │   │
│ │ [🌙 Bedtime] [🎓 Learning] [🚀 Adventure]  │   │
│ └───────────────────────────────────────────┘   │
│                                                  │
│ Child: [Dropdown] Age Range: [Auto-filled]      │
│                                                  │
│ ┌─────────────────────────────────────────┐     │
│ │      [✨ Generate Story with AI]         │     │
│ └─────────────────────────────────────────┘     │
└─────────────────────────────────────────────────┘
```

#### Builder Mode View
```
┌─────────────────────────────────────────────────┐
│ Page 3 of 5                          [+ Add Page]│
├─────────────────────────────────────────────────┤
│                                                  │
│ ┌───────────────────────────────────────────┐   │
│ │ [Image Upload Area]                        │   │
│ │     Drop image here or click to browse     │   │
│ │            🖼️ AI Suggest Images            │   │
│ └───────────────────────────────────────────┘   │
│                                                  │
│ ┌───────────────────────────────────────────┐   │
│ │ Once upon a time, in a magical forest...   │   │
│ │ [Editable text area with formatting]       │   │
│ │                                             │   │
│ │ ✨ (AI suggestion available - hover to see) │   │
│ └───────────────────────────────────────────┘   │
│                                                  │
│ Reading Time: ~2 min | Words: 245 | Level: K-2  │
└─────────────────────────────────────────────────┘
```

#### Focus Mode View
```
┌─────────────────────────────────────────────────┐
│                                                  │
│                                                  │
│     Once upon a time, in a magical forest...    │
│     │ (blinking cursor)                          │
│                                                  │
│                                                  │
│     ··· AI: Press Tab for suggestion ···         │
│                                                  │
│                                                  │
└─────────────────────────────────────────────────┘
```

### 4. Inline AI Suggestions

#### Hover State
```
The little rabbit hopped ┌─────────────────────┐
through the garden and   │ ✨ AI Suggestion:   │
                         │ "discovered a hidden │
                         │ door behind the     │
                         │ rose bushes"        │
                         │                     │
                         │ [Accept] [More]     │
                         └─────────────────────┘
```

#### Text Selection Menu
```
[Selected text highlighted]
  ┌──────────────────────────┐
  │ ✨ Enhance  | ↕ Simplify │
  │ 📝 Rewrite | 🔄 Expand   │
  └──────────────────────────┘
```

### 5. Smart Toolbar

```
┌──────────────────────────────────────────────────────────┐
│ [B][I][U] | [H1][H2][P] | [🎨 Color] | [✨ AI Magic]     │
│ [📎 Image] [🔗 Link] [📋 Template] | [👁️ Preview]        │
└──────────────────────────────────────────────────────────┘
```

**AI Magic Button Dropdown:**
```
┌──────────────────────┐
│ ✨ AI Magic Tools    │
├──────────────────────┤
│ Generate Next Line   │
│ Improve Paragraph    │
│ Add Dialogue         │
│ Describe Scene       │
│ Check Consistency    │
│ Suggest Vocabulary   │
└──────────────────────┘
```

### 6. Story Pages Navigator

```
┌─────────┐
│ Pages   │
├─────────┤
│ ┌─────┐ │
│ │  1  │ │ ← Active page
│ └─────┘ │
│ ┌─────┐ │
│ │  2  │ │
│ └─────┘ │
│ ┌─────┐ │
│ │  3  │ │
│ └─────┘ │
│ ┌─────┐ │
│ │  +  │ │ ← Add new page
│ └─────┘ │
└─────────┘
```

### 7. AI Generation Modal

```
┌─────────────────────────────────────────────────┐
│          ✨ AI Story Generation                 │
├─────────────────────────────────────────────────┤
│                                                  │
│ Tell me your story idea:                        │
│ ┌──────────────────────────────────────────┐    │
│ │ A brave little mouse who...              │    │
│ └──────────────────────────────────────────┘    │
│                                                  │
│ Story Settings:                                 │
│                                                  │
│ Length: [●────○────] 5 pages                    │
│                                                  │
│ Tone:   [Adventure ▼]                           │
│                                                  │
│ Educational Focus:                              │
│ [ ] Vocabulary  [✓] Problem-solving             │
│ [ ] Numbers     [ ] Social skills               │
│                                                  │
│ Advanced Options ▼                              │
│                                                  │
│ [Cancel]              [✨ Generate Story]       │
└─────────────────────────────────────────────────┘
```

### 8. AI Loading States

#### Generating Content
```
┌─────────────────────────────────────────┐
│     ✨ Creating your magical story...    │
│                                          │
│         [Animated sparkles]              │
│      ████████░░░░░░░░░░ 40%            │
│                                          │
│    "Adding characters and plot..."       │
└─────────────────────────────────────────┘
```

#### Streaming Response
```
┌─────────────────────────────────────────┐
│ Once upon a time, in a magical forest   │
│ where the trees whispered secrets and   │
│ the flowers danced in the breeze...│    │
│                                  ⚡      │ ← Typing indicator
└─────────────────────────────────────────┘
```

### 9. Quick Actions Floating Button

```
     ┌────┐
     │ ✨ │  ← Floating in bottom right
     └────┘
       │
┌──────────────┐
│ Quick Actions│
├──────────────┤
│ 📝 New Story │
│ ✨ AI Help   │
│ 💾 Save      │
│ 👁️ Preview   │
└──────────────┘
```

### 10. AI Settings Panel

```
┌─────────────────────────────────────────────────┐
│              AI Assistant Settings              │
├─────────────────────────────────────────────────┤
│                                                  │
│ Auto-Suggestions:     [ON ●━━○ OFF]            │
│                                                  │
│ Suggestion Frequency: [●━━━━○━━━━] Often        │
│                                                  │
│ Writing Style:        [Playful ▼]               │
│                                                  │
│ Complexity Level:     [●━━━○━━━━━] Grade K-2   │
│                                                  │
│ Educational Emphasis:                           │
│ [✓] Vocabulary expansion                        │
│ [✓] Moral lessons                              │
│ [ ] STEM concepts                              │
│ [✓] Social-emotional learning                   │
│                                                  │
│ Privacy:                                        │
│ [ ] Save AI interactions for improvement        │
│ [✓] Use local processing when available        │
│                                                  │
│ [Reset to Defaults]           [Save Settings]   │
└─────────────────────────────────────────────────┘
```

## Responsive Breakpoints

### Desktop (1440px+)
- Full three-panel layout
- All features visible
- Hover interactions enabled

### Laptop (1024px - 1439px)
- AI panel starts collapsed
- Pages navigator as overlay
- Slightly reduced toolbar

### Tablet (768px - 1023px)
- Single column layout
- AI panel as modal
- Touch-optimized controls
- Simplified toolbar

### Mobile (< 768px)
- Read-only mode
- Basic editing only
- No AI features
- Redirect to app download

## Interaction Patterns

### Keyboard Shortcuts Overlay
```
┌─────────────────────────────────────────────────┐
│            Keyboard Shortcuts (?)               │
├─────────────────────────────────────────────────┤
│                                                  │
│ General:                                        │
│   Cmd/Ctrl + S    Save story                   │
│   Cmd/Ctrl + Z    Undo                         │
│   Cmd/Ctrl + Y    Redo                         │
│                                                  │
│ AI Features:                                    │
│   Cmd/Ctrl + G    Generate with AI             │
│   Cmd/Ctrl + E    Enhance selection            │
│   Tab             Accept AI suggestion         │
│   Esc             Dismiss AI panel             │
│   Cmd/Ctrl + R    Regenerate last AI output    │
│                                                  │
│ Navigation:                                     │
│   Cmd/Ctrl + →    Next page                    │
│   Cmd/Ctrl + ←    Previous page                │
│                                                  │
│                              [Got it!]           │
└─────────────────────────────────────────────────┘
```

## Animation Specifications

### Transitions
- Panel slides: 300ms ease-out
- Hover effects: 150ms ease
- AI sparkle pulse: 2s infinite
- Loading bars: smooth linear
- Text generation: typewriter effect

### Micro-interactions
- Button hover: slight scale (1.05)
- AI suggestion appear: fade + slide down
- Success feedback: green flash + checkmark
- Error shake: 300ms horizontal shake

## Color Scheme for AI Elements

```
AI Primary:    #8B5CF6 (Purple)
AI Secondary:  #C084FC (Light Purple)
AI Accent:     #FCD34D (Gold sparkle)
AI Background: #F3F4F6 (Light gray)
AI Text:       #1F2937 (Dark gray)
Success:       #10B981 (Green)
Warning:       #F59E0B (Amber)
Error:         #EF4444 (Red)
```

## Accessibility Features

- All AI controls keyboard navigable
- Screen reader announcements for AI actions
- High contrast mode support
- Reduced motion option
- Focus indicators on all interactive elements
- ARIA labels for all AI features
- Loading state announcements
- Error message clarity