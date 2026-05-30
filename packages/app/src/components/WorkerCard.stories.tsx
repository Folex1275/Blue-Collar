import type { Meta, StoryObj } from '@storybook/react'
import WorkerCard from './WorkerCard'
import { CompareProvider } from '@/context/CompareContext'

const meta: Meta<typeof WorkerCard> = {
  title: 'Components/WorkerCard',
  component: WorkerCard,
  tags: ['autodocs'],
  decorators: [
    (Story) => (
      <CompareProvider>
        <Story />
      </CompareProvider>
    ),
  ],
}

export default meta
type Story = StoryObj<typeof meta>

const mockWorker = {
  id: '1',
  name: 'John Smith',
  category: { id: '1', name: 'Plumber' },
  avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=John',
  isVerified: true,
  averageRating: 4.8,
  reviewCount: 24,
  bio: 'Professional plumber with 10+ years of experience',
  location: 'San Francisco, CA',
  isActive: true,
}

export const Default: Story = {
  args: {
    worker: mockWorker,
  },
}

export const WithoutAvatar: Story = {
  args: {
    worker: {
      ...mockWorker,
      avatar: null,
    },
  },
}

export const WithoutRating: Story = {
  args: {
    worker: {
      ...mockWorker,
      averageRating: null,
      reviewCount: 0,
    },
  },
}

export const Unverified: Story = {
  args: {
    worker: {
      ...mockWorker,
      isVerified: false,
    },
  },
}
