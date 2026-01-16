-- Create the tables for exchange rates, expenses income and fuel consumption.
CREATE TABLE "exchange_rates" (
    "id" INTEGER PRIMARY KEY,
    "country" TEXT NOT NULL,
    "currency" TEXT UNIQUE NOT NULL,
    "exchange_rate" REAL NOT NULL
);

CREATE TABLE "expenses" (
    "id" INTEGER PRIMARY KEY,
    "date" TEXT NOT NULL,
    "name" TEXT,
    "amount" REAL NOT NULL,
    "currency" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    FOREIGN KEY("currency") REFERENCES "exchange_rates"("currency")
);

CREATE TABLE "income" (
    "id" INTEGER PRIMARY KEY,
    "date" TEXT NOT NULL,
    "category" TEXT NOT NULL CHECK("category" IN ('Savings', 'Interest', 'Income')),
    "amount" REAL NOT NULL
);

CREATE TABLE "fuel" (
    "id" INTEGER PRIMARY KEY,
    "date" TEXT NOT NULL,
    "liters" REAL NOT NULL,
    "odometer" INTEGER NOT NULL
);

-- View showing how much has been spent in each currency for each spending category, calculated in AUD for easy comparison.
CREATE VIEW "category_country" AS
SELECT "expenses"."category", "expenses"."currency",
    ROUND(SUM ("expenses"."amount" * "exchange_rates"."exchange_rate"), 2) AS "total AUD per currency and category"
FROM "expenses"
JOIN "exchange_rates"
    ON "exchange_rates"."currency" = "expenses"."currency"
GROUP BY "expenses"."category", "expenses"."currency"
ORDER BY "expenses"."category", "total AUD per currency and category" DESC;

-- View showing average cost per day per currency, calculated in AUD for easy comparison.
CREATE VIEW "average_cost_per_day" AS
SELECT "currency", ROUND(AVG("daily_total"), 2) AS "average_daily_cost_AUD"
FROM (
    SELECT "expenses"."date", "expenses"."currency", SUM("expenses"."amount" * "exchange_rates"."exchange_rate") AS "daily_total"
    FROM "expenses"
    JOIN "exchange_rates" ON "exchange_rates"."currency" = "expenses"."currency"
    GROUP BY "expenses"."date", "expenses"."currency"
)
GROUP BY "currency"
ORDER BY "average_daily_cost_AUD" DESC;

-- View showing amount of money left in the bank in AUD, using COALESCE as per: https://www.sqlitetutorial.net/sqlite-functions/sqlite-coalesce/
CREATE VIEW "current_funds" AS
SELECT ROUND(
    COALESCE((SELECT SUM("amount") FROM "income"), 0)
    -
    COALESCE((SELECT SUM("per_currency"."total" * "exchange_rates"."exchange_rate")
    FROM (
        SELECT "currency", SUM("amount") AS "total"
        FROM "expenses"
        GROUP BY "currency"
    ) AS "per_currency"
    JOIN "exchange_rates" ON "exchange_rates"."currency" = "per_currency"."currency"
    ), 0), 2)
    AS "current balance";

-- Average fuel consumption in liters per 100km driven, using LAG as per: https://www.sqlitetutorial.net/sqlite-window-functions/sqlite-lag/
CREATE VIEW "average_l_per_100km" AS
SELECT ROUND(AVG("liters_per_100km"), 2) AS "avg_L_per_100km"
FROM (
    SELECT "liters" * 100.0 /
    ("odometer" - LAG("odometer") OVER (ORDER BY "date")) AS "liters_per_100km"
    FROM "fuel"
)
WHERE "liters_per_100km" IS NOT NULL;

-- Index to speed up retrieval of currency and expense data from the expenses table.
CREATE INDEX "idx_expenses_per_catergory_currency" ON "expenses"("categpory", "currency");

-- Index to speed up retrieval of currency and date data from the expenses table.
CREATE INDEX "idx_expenses_per_date_currency" ON "expenses" ("date", "currency");
