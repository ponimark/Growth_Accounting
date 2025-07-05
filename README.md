# Growth_Accounting
# 📈 Growth Accounting

This project implements **Growth Accounting** using SQL to track and classify user behavior over time. It segments users into key activity buckets like **New**, **Retained**, **Resurrected**, and **Churned** based on their engagement patterns with the platform.

---

## 📊 What is Growth Accounting?

Growth Accounting helps understand user growth by breaking down active users (daily or weekly) into:

- 🆕 **New** – First time user activity
- 🔁 **Retained** – Continued activity from previous period
- 💡 **Resurrected** – User returns after inactivity
- ❌ **Churned** – User becomes inactive after previously being active
- 💤 **Stale** – No activity and insufficient data

---

## 📂 SQL Script Breakdown

```sql
-- 1. Generate date range (e.g., Jan 2023)
WITH dates AS (
  SELECT * FROM generate_series(DATE '2023-01-01', DATE '2023-01-31', interval '1 day') AS date
),

-- 2. Get each user's first active date
first_data AS (
  SELECT user_id, MIN(DATE(event_time)) AS first_active
  FROM events
  WHERE user_id IS NOT NULL
  GROUP BY user_id
),

-- 3. Create a row for each user for each date from their first activity onwards
merged AS (
  SELECT f.user_id, f.first_active, d.date
  FROM first_data f
  JOIN dates d ON f.first_active <= d.date
),

-- 4. Join with events to check if user was active on each date
duplicate AS (
  SELECT m.*, DATE(e.event_time) AS event_date
  FROM merged m
  LEFT JOIN events e ON m.date = DATE(e.event_time)
                    AND m.user_id = e.user_id
),

-- 5. Remove duplicates to ensure one record per user per day
deduped AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id, date) AS rn
  FROM duplicate
),

-- 6. Track running last active date per user
non_dupli AS (
  SELECT user_id, first_active,
         MAX(event_date) OVER (
           PARTITION BY user_id 
           ORDER BY date 
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
         ) AS last_active,
         date, event_date
  FROM deduped
  WHERE rn = 1
),

-- 7. Get previous active date using lag()
prev AS (
  SELECT *, 
         LAG(last_active) OVER (PARTITION BY user_id ORDER BY date) AS prev_active
  FROM non_dupli
)

-- 8. Final classification
SELECT 
  user_id,
  first_active,
  last_active,
  
  -- Daily activity classification
  CASE 
    WHEN date = first_active THEN 'New'
    WHEN event_date IS NOT NULL AND date - prev_active = 1 THEN 'Retained'
    WHEN event_date IS NOT NULL AND date - prev_active > 1 THEN 'Resurrected'
    WHEN event_date IS NULL AND date - prev_active = 1 THEN 'Churned'
    ELSE 'Stale'
  END AS daily_active,
  
  -- Weekly activity classification
  CASE 
    WHEN date = first_active THEN 'New'
    WHEN event_date IS NOT NULL AND date - prev_active <= 7 THEN 'Retained'
    WHEN event_date IS NOT NULL AND date - prev_active > 7 THEN 'Resurrected'
    WHEN event_date IS NULL AND date - prev_active <= 7 THEN 'Churned'
    ELSE 'Stale'
  END AS weekly_active,

  -- Dates user was active (as array)
  ARRAY_REMOVE(
    ARRAY_AGG(CASE WHEN event_date IS NOT NULL THEN date ELSE NULL END)
      OVER (PARTITION BY user_id ORDER BY date),
    NULL
  ) AS date_active,

  -- The current date
  date

FROM prev;
