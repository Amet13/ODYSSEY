---

name: "✨ Feature Request"
description: "Suggest a new feature or improvement for ODYSSEY."
title: "[Feature] "
labels: [enhancement]
assignees: []
body:

- type: markdown
  attributes:
  value: | ## ✨ Feature Request
  Please describe your idea or suggestion in detail.

- type: input
  id: summary
  attributes:
  label: "Summary"
  description: "A clear and concise description of the feature."
  placeholder: "Add support for..."
  validations:
  required: true

- type: textarea
  id: motivation
  attributes:
  label: "Motivation"
  description: "Why is this feature important? What problem does it solve?"
  placeholder: "This would help users by..."
  validations:
  required: true

- type: textarea
  id: proposal
  attributes:
  label: "Proposed Solution"
  description: "Describe your proposed solution or implementation."
  placeholder: "I suggest..."
  validations:
  required: false

- type: textarea
  id: alternatives
  attributes:
  label: "Alternatives Considered"
  description: "Have you considered any alternative solutions?"
  placeholder: "Alternatively, we could..."
  validations:
  required: false

- type: checkboxes
  id: terms
  attributes:
  label: "Checklist"
  options: - label: "I have searched existing issues."
  required: true - label: "I am not requesting a duplicate feature."
  required: true
