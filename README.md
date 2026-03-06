# 🗓️ BookIt

**BookIt** is a premium, high-performance Flutter application designed to bridge the gap between service providers and their clients. Whether you're a barber, a personal trainer, or a consultant, BookIt provides a seamless, real-time booking experience with a sophisticated aesthetic.

---

## ✨ Key Features

### 👤 For Customers
- **Discovery**: Search and explore top-rated service providers in your area.
- **Dynamic Previews**: View provider profiles that intelligently adapt their theme based on business category.
- **Smart Booking**: Choose services and select available time slots with real-time conflict detection.
- **Management**: Track your upcoming and past appointments, and reschedule with ease.

### 💼 For Service Providers
- **Role-Based Dashboards**: Manage your business, services, and availability in one dedicated hub.
- **Automated Scheduling**: Define your working hours and let the system handle slots based on current bookings.
- **Client Overviews**: View detailed information about your upcoming clients and their specific needs.
- **Profile Customization**: Manage your business metadata, emoji branding, and service listings.

---

## 🛠️ Technology Stack

- **Frontend**: [Flutter](https://flutter.dev/) (3.x)
- **Backend**: [Supabase](https://supabase.com/) (PostgreSQL, Auth, RLS)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Typography & Theme**: Google Fonts (Fraunces & DM Sans), Custom Glassmorphic UI

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A [Supabase Project](https://supabase.com/) configured with the appropriate database schema.

### 2. Configuration
Create a `.env` file in the project root and add your Supabase credentials:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Jnix272/book_app.git
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 🔒 Security
The application leverages **Supabase Row Level Security (RLS)** and strong password validation (8+ characters, symbols, and mixed cases) to ensure user data remains private and protected at all times.

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
