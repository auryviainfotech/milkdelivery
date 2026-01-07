# **Milk Order Subscription Management System**

## **System Architecture (High-Level)**

\[ Customer App \]         \[ Delivery App \]

        │                       │

        └────── REST APIs ──────┘

                    │

              \[ Backend Server \]

                    │

              \[ Database \]

                    │

              \[ Admin Web Panel \]

## **Customer App – Visual Flow Diagram**

`[ Splash Screen ]`  
        `↓`  
`[ Login / Register ]`  
        `↓`  
`[ Customer Dashboard ]`  
        `↓`  
 `┌───────────────┬───────────────┬───────────────┐`  
 `│               │               │               │`  
 `▼               ▼               ▼               ▼`  
`[ Wallet ]   [ Subscriptions ] [ Orders ] [ Profile ]`  
   `│               │               │               │`  
   `▼               ▼               ▼               ▼`  
`[ Recharge ]  [ Select Milk ]  [ Order Details ] [ Change Password ]`  
   `│               │`  
   `▼               ▼`  
`[ Payment ]   [ Confirm Plan ]`  
                   `│`  
                   `▼`  
           `[ Wallet Balance Check ]`  
                   `│`  
        `┌──────────┴──────────┐`  
        `│                     │`  
      `Yes                    No`  
        `│                     │`  
        `▼                     ▼`  
`[ Subscription Active ]   [ Recharge Wallet ]`

### **UX Notes**

* Wallet balance check must be **instant**

* 10 PM cutoff banner shown on dashboard

* Notifications after every action

## **Delivery App – Visual Flow Diagram**

`[ Splash Screen ]`  
        `↓`  
`[ Delivery Login ]`  
        `↓`  
`[ Delivery Dashboard ]`  
        `↓`  
`[ Today's Route List ]`  
        `↓`  
`[ Select Customer ]`  
        `↓`  
`[ Navigate via Maps ]`  
        `↓`  
`[ Scan QR Code ]`  
        `↓`  
`[ Confirm Delivery ]`  
        `↓`  
      `┌───────┴────────┐`  
      `│                │`  
    `Success         Issue`  
      `│                │`  
      `▼                ▼`  
`[ Mark Delivered ] [ Report Problem ]`

### **UX Notes**

* One-tap navigation

* QR scan is mandatory

* Offline handling (basic)

## **Admin Panel – Visual Flow Diagram**

`[ Admin Login ]`

        `↓`

`[ Admin Dashboard ]`

        `↓`

 `┌───────────┬───────────┬───────────┬───────────┐`

 `│           │           │           │           │`

 `▼           ▼           ▼           ▼           ▼`

`Products  Customers  Subscriptions  Wallets   Reports`

   `│           │           │           │           │`

   `▼           ▼           ▼           ▼           ▼`

`Add/Edit   View List  10 PM Cutoff  Verify Pay  Export Excel`

   `│                       │`

   `▼                       ▼`

`Set Price        Generate Delivery Routes`

### **UX Notes**

* 10 PM cutoff should be **automated**

* Route generation is admin-triggered

* Reports downloadable as Excel

### **Recommended Enhancements**

* Pause / resume subscription  
* Auto low-balance recharge  
* Role-based access control  
* Delivery time-slot tracking  
* Holiday skip logic  
* Pause subscription option

# 

