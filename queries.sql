-- Common import to add more expenses:
.import --csv Expenses.csv temp
INSERT INTO "expenses" ("date", "name", "amount", "currency", "category")
SELECT "date", "name", "amount", "currency", "category" FROM "temp";

-- Common import to add more fuel data:
.import --csv Fuel.csv temp
INSERT INTO "fuel" ("date", "liters", "odometer")
SELECT "date", "liters", "odometer" FROM "temp";

-- Adding a currency when visiting a new country before importing expenses in that currency:
INSERT INTO "exchange_rates" ("country", "currency", "exchange_rate")
VALUES ('insert_country_name', 'insert_currecy_abreviation', 'insert_exchange_rate'); -- These are examples.

-- Adding income to the income table for income or interest, very rare but usefull when needed:
INSERT INTO "income" ("date", "category", "amount")
VALUES ('0000-00-00', 'interest', '100'); -- These are examples.

-- View to check total spent per category per currency/country converted to AUD:
SELECT * FROM "category_country";

-- View to check average cost per day per currency converted to AUD:
SELECT * FROM "average_cost_per_day";

-- View to check how much money is currently left to travel for:
SELECT * FROM "current_funds";

-- View to check average fuel usage in liters per 100km traveled:
SELECT * FROM "average_l_per_100km";

-- Querying how much has been spent between two dates in the past, converted to AUD.
SELECT "expenses"."id", "expenses"."date", "expenses"."name", "expenses"."amount", "expenses"."currency", "expenses"."category",
    ROUND("expenses"."amount" * "exchange_rates"."exchange_rate", 2) AS "amount in AUD"
FROM "expenses"
JOIN "exchange_rates" ON "exchange_rates"."currency" = "expenses"."currency"
WHERE "expenses"."date" BETWEEN '2025-01-01' AND '2025-02-01'; -- Change the dates to suit the period you are looking for.

-- Querying how much has been spent in some categories between two dates in the past, converted to AUD.
SELECT "expenses"."id", "expenses"."date", "expenses"."name", "expenses"."amount", "expenses"."currency", "expenses"."category",
    ROUND("expenses"."amount" * "exchange_rates"."exchange_rate", 2) AS "amount in AUD"
FROM "expenses"
JOIN "exchange_rates" ON "exchange_rates"."currency" = "expenses"."currency"
WHERE "expenses"."date" BETWEEN '2025-01-01' AND '2025-02-01' -- Change the dates to suit the period you are looking for.
AND "name" = 'Fika' OR "name" = 'Lunch' OR "name" = 'Dinner'; -- Change the names selected to suit your needs.

-- Querying average fuel consumption between certain dates, using LAG as per: https://www.sqlitetutorial.net/sqlite-window-functions/sqlite-lag/
SELECT ROUND(AVG("liters_per_100km"), 2) AS "avg_L_per_100km"
FROM (
    SELECT "date", "liters" * 100.0 /
    ("odometer" - LAG("odometer") OVER (ORDER BY "date")) AS "liters_per_100km"
    FROM "fuel"
)
WHERE "liters_per_100km" IS NOT NULL
AND "date" BETWEEN '2025-01-01' AND '2025-05-01';
