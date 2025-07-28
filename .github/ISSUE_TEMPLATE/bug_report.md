---

name: "🐞 Bug Report"
description: "Report a bug to help us improve ODYSSEY."
title: "[Bug] "
labels: [bug]
assignees: []
body:

- type: markdown
  attributes:
  value: | ## 🐞 Bug Report
  Please fill out the following information to help us reproduce and fix the issue.

- type: input
  id: summary
  attributes:
  label: "Summary"
  description: "A clear and concise description of the bug."
  placeholder: "The app crashes when..."
  validations:
  required: true

- type: textarea
  id: steps
  attributes:
  label: "Steps to Reproduce"
  description: "How can we reproduce the bug?"
  placeholder: "1. Go to...\n2. Click on...\n3. See error..."
  validations:
  required: true

- type: textarea
  id: expected
  attributes:
  label: "Expected Behavior"
  description: "What did you expect to happen?"
  placeholder: "The app should..."
  validations:
  required: true

- type: textarea
  id: actual
  attributes:
  label: "Actual Behavior"
  description: "What actually happened?"
  placeholder: "Instead, the app..."
  validations:
  required: true

- type: input
  id: version
  attributes:
  label: "App Version"
  description: "Which version of ODYSSEY are you using? (see About or version badge)"
  placeholder: "e.g. 1.0.0"
  validations:
  required: false

- type: input
  id: os
  attributes:
  label: "macOS Version"
  description: "Which version of macOS are you using?"
  placeholder: "e.g. macOS 15"
  validations:
  required: false

- type: textarea
  id: logs
  attributes:
  label: "Relevant Logs / Screenshots"
  description: "Paste any relevant logs, error messages, or screenshots."
  placeholder: "Paste logs or drag screenshots here."
  validations:
  required: false

- type: checkboxes
  id: terms
  attributes:
  label: "Checklist"
  options: - label: "I have searched existing issues."
  required: true - label: "I am not reporting a duplicate."
  required: true
