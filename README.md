<div align="center">

<img src="assets/sporg-logo.png" alt="SPORG Logo" width="150"/>

SPORG - SPOT Organization App 🚀

A comprehensive event management and attendance tracking solution for SPOT (Skilled Physicians of Tanta).

</div>

📖 Overview

SPORG is a modern mobile application built to streamline operations for SPOT. It replaces traditional paper-based systems with a digital solution offering real-time data synchronization using GitHub as a Backend (JSON storage) and Firebase Cloud Messaging for instant notifications.

🌟 Key Features

🔐 Authentication & Security

Role-Based Access: Distinct dashboards for Admins (Computer Team, HR) and Regular Members.

Secure Login: Credentials validated against the remote GitHub database.

📱 Attendance System

QR Scanning: High-speed scanning using mobile_scanner.

Smart Parsing: Automatically detects and parses member IDs from various QR formats.

Manual Entry: Fallback mode for manual attendance marking.

Dynamic Roles: Assign session roles (Organizer, Trainer, etc.) instantly.

📊 Data Analytics

Real-time Stats: Live counters for present vs. absent members.

Visual Reports: Interactive Pie Charts showing attendance distribution by team.

Team Breakdown: Detailed analysis of participation per committee.

☁️ Connectivity

Serverless Backend: Innovative use of GitHub API to read/write JSON data directly.

Push Notifications: Integrated Firebase FCM (HTTP v1) for broadcasting updates to all members even when the app is closed.

📂 Export & Sharing

CSV Export: One-click export of detailed attendance reports.

Social Sharing: Share reports directly to WhatsApp or Telegram.

🛠️ Tech Stack

Category

Technology

Framework

Flutter (Dart)

State Management

Provider

Backend

GitHub REST API (JSON)

Notifications

Firebase Cloud Messaging (FCM)

Charts

FL Chart

Tools

Mobile Scanner, CSV, Path Provider

📸 Screenshots

<div align="center">

Login Screen

Dashboard

QR Scanner

Analysis

<img src="screenshots/1.png" height="400">

<img src="screenshots/2.png" height="400">

<img src="screenshots/3.png" height="400">

<img src="screenshots/4.png" height="400">

</div>

Note: Please ensure you add screenshots to a screenshots folder in your repository named 1.png through 4.png.

🚀 Getting Started

Prerequisites

Flutter SDK

Android Studio / VS Code

Git

Installation

Clone the repository:

git clone [https://github.com/melabbasi/SPORG.git](https://github.com/melabbasi/SPORG.git)


Navigate to the project directory:

cd sporg


Install dependencies:

flutter pub get


Configuration (Secrets):

⚠️ Important: This app requires confidential keys not included in the repo.

GitHub Token: Update AppProvider with your Personal Access Token.

Firebase Key: Update AppProvider with your Service Account Private Key.

Run the app:

flutter run


🔒 Security Note

This application is an internal tool developed for SPOT. It utilizes hardcoded tokens to simplify distribution among the specific admin team. For a public production release, it is highly recommended to migrate token logic to a secure backend server to protect your credentials.

👨‍💻 Developer

<div align="center">

Mohamed El-Abbasi

Medical Student @ Tanta University (Batch 68)





Vice Moderator, Computer Team @ SPOT





Vice Moderator, HR Team @ SPOT

Made with ❤️ for SPOT

</div>
