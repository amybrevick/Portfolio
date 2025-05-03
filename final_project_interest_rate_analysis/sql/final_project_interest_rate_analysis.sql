CREATE TABLE interest_rates (
	date DATE PRIMARY KEY,
	tbill_3mo NUMERIC(6,2),
	libor NUMERIC(6,2),
	sofr_avg NUMERIC(6,2),
	fed_funds_avg NUMERIC(6,2),
	tsec_10yr_avg NUMERIC(6,2),
	moody_aaa NUMERIC(6,2)
);

CREATE TABLE market_data (
	date DATE PRIMARY KEY,
	sp500_index_real NUMERIC(12,2),
	sp500_index_nominal NUMERIC(12,2),
	djia_index_real NUMERIC(12,2),
	djia_index_nominal NUMERIC(12,2),
	nasdaq100_index_avg NUMERIC(12,2)	
);

CREATE TABLE economic_indicators (
	date DATE PRIMARY KEY,
	gdp NUMERIC(20,2),
	core_cpi_index NUMERIC(6,2),
	cpi_index NUMERIC(6,2),
	breakeven_rate_avg NUMERIC(6,2),
	ipi_index NUMERIC(6,2),
	ppi_index NUMERIC(6,2),
	total_employees NUMERIC(20,2),
	unemployment_rate NUMERIC(6,2),
	crude_oil_price NUMERIC(10,2), 
	gold_price NUMERIC(10,2),
	silver_price NUMERIC(10,2)
);

CREATE TABLE housing_data (
	date DATE PRIMARY KEY,
	real_estate_credit NUMERIC(20,2),
	housing_price_index NUMERIC(6,2),
	prime_rate NUMERIC(4,2),
	housing_inventory NUMERIC(20,2),
	mortgage_rates_avg NUMERIC(4,2),
	homes_sold NUMERIC(20,2)
);

CREATE TABLE credit_data (
	date DATE PRIMARY KEY,
	consumer_credit_outstanding NUMERIC(20,2),
	charge_off_rate NUMERIC(6,2),
	consumer_loans_delinquency_rate NUMERIC(6,2),
	household_debt_service_ratio NUMERIC(6,2),
	total_bank_credit NUMERIC(20,2)
);

CREATE TABLE exchange_rates (
	date DATE PRIMARY KEY,
	usd_fx_index NUMERIC(6,2),
	aud_usd NUMERIC(6,2),
	eur_usd NUMERIC(6,2),
	gbp_usd NUMERIC(6,2),
	cad_usd NUMERIC(6,2),
	cny_usd NUMERIC(6,2),
	jpy_usd NUMERIC(6,2),
	chf_usd NUMERIC(6,2)
);

CREATE TABLE sentiment_data (
	date DATE PRIMARY KEY,
	vix_index_avg NUMERIC(6,2),
	business_sentiment NUMERIC(6,2),
	consumer_sentiment NUMERIC(6,2),
	google_inflation_trend NUMERIC(6,2),
	google_interest_rate_trend NUMERIC(6,2),
	google_mortgage_rate_trend NUMERIC(6,2),
	consumer_confidence_index NUMERIC(6,2)
);

CREATE TABLE cryptocurrency (
	date DATE PRIMARY KEY,
	btc_price NUMERIC(20,2),
	btc_volume NUMERIC(20,2),
	btc_market_cap NUMERIC(20,2),
	eth_price NUMERIC(20,2),
	eth_volume NUMERIC(20,2),
	eth_market_cap NUMERIC(20,2)
);



--STOP AND IMPORT DATA
--STOP AND IMPORT DATA
--STOP AND IMPORT DATA
--STOP AND IMPORT DATA
--STOP AND IMPORT DATA



--CREDIT MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM credit_data
WHERE date < '1975-01-01';

--add real estate credit outstanding from housing table
ALTER TABLE credit_data ADD COLUMN real_estate_credit_outstanding NUMERIC;

UPDATE credit_data c
SET real_estate_credit_outstanding = h.real_estate_credit
FROM housing_data h
WHERE c.date = h.date;

--adding a column for total credit outstanding which includes consumer credit plus real estate
ALTER TABLE credit_data ADD COLUMN total_credit_outstanding NUMERIC;
UPDATE credit_data
SET total_credit_outstanding = ROUND(
	consumer_credit_outstanding + real_estate_credit_outstanding, 2);

--adding feb 2025 to total_bank_credit
UPDATE credit_data
SET total_bank_credit = 18027509100000.00
WHERE date = '2025-02-28';

--adding a column for total credit exposure ratio to see how much of bank credit tied up in consumer & real estate debt
--total bank credit includes business, ag, leases, securities, assets and reserves
--consumer credit outstanding is total non-mortgage debt owed by households ie. auto, credit cards, etc.
--real estate credit outstanding is total mortgage credit held by bank
--total_credit_exposure_ratio is a benchmark to see how much total bank credit is explained by consumer and real estate credit
ALTER TABLE credit_data ADD COLUMN consumer_credit_exposure_ratio NUMERIC;
UPDATE credit_data
SET consumer_credit_exposure_ratio = 
	ROUND(consumer_credit_outstanding / total_bank_credit, 2);

ALTER TABLE credit_data ADD COLUMN real_estate_exposure_ratio NUMERIC;
UPDATE credit_data
SET real_estate_exposure_ratio = 
	ROUND(real_estate_credit_outstanding / total_bank_credit, 2);

ALTER TABLE credit_data ADD COLUMN total_credit_exposure_ratio NUMERIC;
UPDATE credit_data
SET total_credit_exposure_ratio = 
	ROUND(total_credit_outstanding / total_bank_credit, 2);



--CRYPTO MANIPULATIONS

--deleting all data prior to inception
DELETE FROM cryptocurrency
WHERE date < '2010-07-01';

--manual insert updating 3/31 values because data was pulled before 3/31 and then have to update circulating supply
DELETE FROM cryptocurrency
WHERE date = '2025-03-31';

INSERT INTO cryptocurrency (
	date, btc_price, btc_volume, btc_market_cap, 
	eth_price, eth_volume, eth_market_cap
)
VALUES (
	'2025-03-31', 
	82541.29, 38919650975.466896, 1633849331577.0662, 
	1823.6653, 20822826161.770035, 219154114710.45645
);

--adding circulating supply column
ALTER TABLE cryptocurrency
ADD COLUMN btc_circulating_supply NUMERIC;
UPDATE cryptocurrency
SET btc_circulating_supply = ROUND(btc_market_cap / btc_price, 2);

ALTER TABLE cryptocurrency
ADD COLUMN eth_circulating_supply NUMERIC;
UPDATE cryptocurrency
SET eth_circulating_supply = ROUND(eth_market_cap / eth_price, 2);



--ECONOMIC INDICATOR MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM economic_indicators
WHERE date < '1975-01-01';

--adding a column for real gdp, gdp adjusted for inflation to reflect true growth rather than just price increases
ALTER TABLE economic_indicators ADD COLUMN gdp_real NUMERIC;
UPDATE economic_indicators
SET gdp_real =
	gdp / cpi_index;

--adding a column to show unemployment as low, moderate, or high
ALTER TABLE economic_indicators ADD COLUMN unemployment_rate_level TEXT;
UPDATE economic_indicators
SET unemployment_rate_level = CASE
	WHEN unemployment_rate < 4 THEN 'Low'
	WHEN unemployment_rate BETWEEN 4 and 6 THEN 'Moderate'
	WHEN unemployment_rate >6 THEN 'High'
	ELSE 'Unknown'
END;
	
--adding a column for yoy change in gdp_real 
ALTER TABLE economic_indicators ADD COLUMN gdp_real_yoy_change NUMERIC;

UPDATE economic_indicators e1
SET gdp_real_yoy_change = ROUND(
	(e1.gdp_real - e2.gdp_real) / e2.gdp_real * 100, 2
)
FROM economic_indicators e2
WHERE e1.date = (e2.date + INTERVAL '1 year');

--yoy not calc'ing correct with february months so fixing
UPDATE economic_indicators
SET gdp_real_yoy_change = NULL;

UPDATE economic_indicators AS e1
SET gdp_real_yoy_change = ROUND(
	(e1.gdp - e2.gdp) / e2.gdp * 100, 2
)
FROM economic_indicators AS e2
WHERE
	EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date)
	AND EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1;

--adding yoy and mom inflation using cpi_index
ALTER TABLE economic_indicators ADD COLUMN inflation_yoy NUMERIC;
UPDATE economic_indicators e1
SET inflation_yoy = ROUND(
	(e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2
)
FROM economic_indicators e2
WHERE
	EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date)
	AND EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1; 

ALTER TABLE economic_indicators ADD COLUMN inflation_mom NUMERIC;
UPDATE economic_indicators e1
SET inflation_mom = ROUND(
	(e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2
)
FROM economic_indicators e2
WHERE
	EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date)
	AND EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date) + 1; 

--adding mom and yoy inflation using core_cpi_index
ALTER TABLE economic_indicators ADD COLUMN core_inflation_mom NUMERIC;
UPDATE economic_indicators e1
SET core_inflation_mom = ROUND(
	(e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2
)
FROM economic_indicators e2
WHERE
	EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date)
	AND EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date) + 1; 

ALTER TABLE economic_indicators ADD COLUMN core_inflation_yoy NUMERIC;
UPDATE economic_indicators e1
SET core_inflation_yoy = ROUND(
	(e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2
)
FROM economic_indicators e2
WHERE
	EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date)
	AND EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1; 

--updating mom calcs because not working correctly
UPDATE economic_indicators e1
SET core_inflation_mom = ROUND(
    (e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2
)
FROM economic_indicators e2
WHERE (
    (EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date)
     AND EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date) + 1)
    OR
    (EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1
     AND EXTRACT(MONTH FROM e1.date) = 1
     AND EXTRACT(MONTH FROM e2.date) = 12)
);

UPDATE economic_indicators e1
SET inflation_mom = ROUND(
    (e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2
)
FROM economic_indicators e2
WHERE (
    (EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date)
     AND EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date) + 1)
    OR
    (EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1
     AND EXTRACT(MONTH FROM e1.date) = 1
     AND EXTRACT(MONTH FROM e2.date) = 12)
);



--EXCHANGE RATE MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM exchange_rates
WHERE date < '1975-01-01';

--manual insert adding 3/31 data that was unavailable when initially downloaded
INSERT INTO exchange_rates (
	date, usd_fx_index, aud_usd, eur_usd, gbp_usd, cad_usd, cny_usd, jpy_usd, chf_usd
)
VALUES (
	'2025-03-31', 
	126.4864, 0.63, 1.0813, 1.2913, 1.4356, 7.2493, 149.0576, 0.8836
);

--adding a column for usd volatility
ALTER TABLE exchange_rates ADD COLUMN usd_fx_index_volatility NUMERIC;
UPDATE exchange_rates
SET usd_fx_index_volatility = sub.stddev
FROM (
	SELECT date,
		STDDEV_SAMP(usd_fx_index) OVER (
			ORDER BY date
			ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
		) AS stddev
	FROM exchange_rates
) sub
WHERE exchange_rates.date = sub.date;

--add a column to show usd strength compared to other major currencies
ALTER TABLE exchange_rates ADD COLUMN usd_strength_level TEXT;
UPDATE exchange_rates
SET usd_strength_level = CASE
	WHEN usd_fx_index < 90 THEN 'Low'
	WHEN usd_fx_index BETWEEN 90 AND 105 then 'Moderate'
	WHEN usd_fx_index > 105 THEN 'Strong'
	ELSE 'Uknown'
END;

--add column to show average monthly usd exchange rate across all currencies
ALTER TABLE exchange_rates ADD COLUMN usd_average_fx_rate NUMERIC;
UPDATE exchange_rates
SET usd_average_fx_rate = ROUND(
	(aud_usd + eur_usd + gbp_usd + cad_usd + cny_usd + jpy_usd + chf_usd) / 7, 4
)
WHERE eur_usd IS NOT NULL AND cny_usd IS NOT NULL;



--HOUSING MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM housing_data
WHERE date < '1975-01-01';

--add column for monthly housing credit change to show month-to-month change in real estate lending
ALTER TABLE housing_data ADD COLUMN real_estate_credit_mom_change NUMERIC;
UPDATE housing_data h1
SET real_estate_credit_mom_change = ROUND(
h1.real_estate_credit - h2.real_estate_credit, 2
)
FROM housing_data h2
WHERE h1.date = (h2.date + INTERVAL '1 month');

--mom % change not calc'ing correct so fixing
UPDATE housing_data SET real_estate_credit_mom_change = NULL;

UPDATE housing_data h1
SET real_estate_credit_mom_change = ROUND(
	(h1.real_estate_credit - h2.real_estate_credit) 
	/ NULLIF(h2.real_estate_credit, 0) * 100, 2
)
FROM housing_data h2
WHERE
	EXTRACT(YEAR FROM h1.date) = EXTRACT(YEAR FROM h2.date)
	AND EXTRACT(MONTH FROM h1.date) = EXTRACT(MONTH FROM h2.date) + 1
	
	OR (EXTRACT(MONTH FROM h1.date) = 1
		AND EXTRACT(MONTH FROM h2.date) = 12
		AND EXTRACT(YEAR FROM h1.date) = EXTRACT(YEAR FROM h2.date) + 1);

--add column to categorize mortgage rates
ALTER TABLE housing_data ADD COLUMN mortgage_rate_level TEXT;
UPDATE housing_data
SET mortgage_rate_level = CASE
	WHEN mortgage_rates_avg < 4 THEN 'Low'
	WHEN mortgage_rates_avg >= 4 AND mortgage_rates_avg <= 6 THEN 'Medium'
	WHEN mortgage_rates_avg > 6 THEN 'High'
	ELSE 'Unknown'
END;

--add column for home price to mortgage rate ratio to show affordability
ALTER TABLE housing_data ADD COLUMN price_to_mortgage_rate_ratio NUMERIC;
UPDATE housing_data
SET price_to_mortgage_rate_ratio = ROUND(
	housing_price_index / mortgage_rates_avg, 2
)
WHERE mortgage_rates_avg IS NOT NULL AND housing_price_index IS NOT NULL;

--updating real_estate_credit_mom_change because not calc'ing correctly
UPDATE housing_data h1
SET real_estate_credit_mom_change = ROUND(
    (h1.real_estate_credit - h2.real_estate_credit) / h2.real_estate_credit * 100, 2
)
FROM housing_data h2
WHERE (
    (EXTRACT(YEAR FROM h1.date) = EXTRACT(YEAR FROM h2.date)
     AND EXTRACT(MONTH FROM h1.date) = EXTRACT(MONTH FROM h2.date) + 1)
    OR
    (EXTRACT(YEAR FROM h1.date) = EXTRACT(YEAR FROM h2.date) + 1
     AND EXTRACT(MONTH FROM h1.date) = 1
     AND EXTRACT(MONTH FROM h2.date) = 12)
);



--INTEREST RATE MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM interest_rates
WHERE date < '1975-01-01';

--adding column for yield curve proxy, difference between long and short term rates
ALTER TABLE interest_rates ADD COLUMN yield_curve_proxy NUMERIC;
UPDATE interest_rates
SET yield_curve_proxy = tsec_10yr_avg - tbill_3mo;

--adding a column for policy stance rate
ALTER TABLE interest_rates ADD COLUMN policy_stance_rate NUMERIC;
UPDATE interest_rates
SET policy_stance_rate = COALESCE(libor, sofr_avg, fed_funds_avg);

--adding a column for policy stance to show how 'tight' or 'loose' fed's monetary policy is
ALTER TABLE interest_rates ADD COLUMN policy_stance TEXT;
UPDATE interest_rates
SET policy_stance = CASE
	WHEN fed_funds_avg >= tbill_3mo AND fed_funds_avg >= sofr_avg THEN 'Hawkish'
	WHEN fed_funds_avg <= tbill_3mo AND fed_funds_avg <= sofr_avg THEN 'Dovish'
	ELSE 'Neutral'
END;

--inserting 3/31 values now available
INSERT INTO interest_rates (
	date, tbill_3mo, libor, sofr_avg, fed_funds_avg, tsec_10yr_avg, moody_aaa
)
VALUES (
	'2025-03-31', NULL, NULL, 4.321578947368421, 4.33, 4.2709090909090905, NULL
)



--MARKET DATA MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM market_data
WHERE date < '1975-01-01';

--adding a column to show market momentum showing month-over-month % change in sp500_real
ALTER TABLE market_data ADD COLUMN market_momentum NUMERIC;

UPDATE market_data m1
SET market_momentum = ROUND(
	(m1.sp500_index_real - m2.sp500_index_real) 
	/ NULLIF(m2.sp500_index_real, 0) * 100, 2
)
FROM market_data m2
WHERE
	EXTRACT(YEAR FROM m1.date) = EXTRACT(YEAR FROM m2.date)
	AND EXTRACT(MONTH FROM m1.date) = EXTRACT(MONTH FROM m2.date) + 1
	
	OR (EXTRACT(MONTH FROM m1.date) = 1
		AND EXTRACT(MONTH FROM m2.date) = 12
		AND EXTRACT(YEAR FROM m1.date) = EXTRACT(YEAR FROM m2.date) + 1);

--add column for trend labeling
ALTER TABLE market_data ADD COLUMN market_trend TEXT;

UPDATE market_data
SET market_trend = CASE
	WHEN market_momentum >= 2 THEN 'Bullish'
	WHEN market_momentum <= -2 THEN 'Bearish'
	ELSE 'Neutral'
END;

--add column for nasdaq 3 month rolling average
ALTER TABLE market_data ADD COLUMN nasdaq100_index_rolling_avg NUMERIC;
WITH rolling_avg AS (
	SELECT date,
		ROUND(AVG(nasdaq100_index_avg) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS avg_val
	FROM market_data
)
UPDATE market_data m
SET nasdaq100_index_rolling_avg = r.avg_val
FROM rolling_avg r
WHERE m.date = r.date;

--adding a nasdaq real value column using cpi index to calc
ALTER TABLE market_data ADD COLUMN nasdaq100_index_avg_real NUMERIC;
UPDATE market_data m
SET nasdaq100_index_avg_real = ROUND(
	m.nasdaq100_index_avg / e.cpi_index, 2
)
FROM economic_indicators e
WHERE m.date = e.date
	AND m.nasdaq100_index_avg_real IS NOT NULL
	AND e.cpi_index IS NOT NULL;



--SENTIMENT DATA MANIPULATIONS

--removing all prior to 1975 for 50 years only
DELETE FROM sentiment_data
WHERE date < '1975-01-01';

--adding column for vix volatility levels
ALTER TABLE sentiment_data ADD COLUMN vix_volatility_level TEXT;

UPDATE sentiment_data
SET vix_volatility_level = CASE
	WHEN vix_index_avg < 12 THEN 'Low'
	WHEN vix_index_avg BETWEEN 15 AND 20 THEN 'Normal'
	ELSE 'High'
END;

--add feb and march consumer sentiment because it was just released
--adding 2/28 and 3/31 consumer_sentiment since have data now
UPDATE sentiment_data
SET consumer_sentiment = 64.7
WHERE date = '2025-02-28';

UPDATE sentiment_data
SET consumer_sentiment = 57
WHERE date = '2025-03-31';

--add column mom change in consumer sentiment
ALTER TABLE sentiment_data ADD COLUMN consumer_sentiment_mom_change NUMERIC;

UPDATE sentiment_data s1
SET consumer_sentiment_mom_change = ROUND(
	(s1.consumer_sentiment - s2.consumer_sentiment) 
	/ NULLIF(s2.consumer_sentiment, 0) * 100, 2
)
FROM sentiment_data s2
WHERE
	EXTRACT(YEAR FROM s1.date) = EXTRACT(YEAR FROM s2.date)
	AND EXTRACT(MONTH FROM s1.date) = EXTRACT(MONTH FROM s2.date) + 1
	
	OR (EXTRACT(MONTH FROM s1.date) = 1
		AND EXTRACT(MONTH FROM s2.date) = 12
		AND EXTRACT(YEAR FROM s1.date) = EXTRACT(YEAR FROM s2.date) + 1);

--add column to label consumer sentiment levels
ALTER TABLE sentiment_data ADD COLUMN consumer_sentiment_level TEXT;

UPDATE sentiment_data
SET consumer_sentiment_level = CASE
	WHEN consumer_sentiment < 80 THEN 'Low'
	WHEN consumer_sentiment BETWEEN 80 AND 100 THEN 'Moderate'
	ELSE 'High'
END;

--updating consumer_sentiment_mom_change because not calc'ing correctly
UPDATE sentiment_data s1
SET consumer_sentiment_mom_change = ROUND(
    (s1.consumer_sentiment - s2.consumer_sentiment) / s2.consumer_sentiment * 100, 2
)
FROM sentiment_data s2
WHERE (
    (EXTRACT(YEAR FROM s1.date) = EXTRACT(YEAR FROM s2.date)
     AND EXTRACT(MONTH FROM s1.date) = EXTRACT(MONTH FROM s2.date) + 1)
    OR
    (EXTRACT(YEAR FROM s1.date) = EXTRACT(YEAR FROM s2.date) + 1
     AND EXTRACT(MONTH FROM s1.date) = 1
     AND EXTRACT(MONTH FROM s2.date) = 12)
);



--QUERIES

--1 yield curve to identify recession warning signals, inverted
SELECT date, tsec_10yr_avg - fed_funds_avg AS curve_spread
FROM interest_rates 
WHERE (tsec_10yr_avg - fed_funds_avg) < 0
ORDER BY date;

--2 avg fed funds rate and avg cpi by year to show how monetary policy and inflation move together
SELECT
	EXTRACT(YEAR FROM ir.date)::INT AS year,
	ROUND(AVG(ir.fed_funds_avg), 2) AS avg_fed_funds_avg,
	ROUND(AVG(e.cpi_index), 2) AS avg_cpi_index
FROM interest_rates ir
JOIN economic_indicators e
	ON ir.date = e.date
GROUP BY year
ORDER BY year;

--3 highest mortgage rate date
SELECT date, mortgage_rates_avg FROM housing_data
WHERE mortgage_rates_avg = (SELECT MAX(mortgage_rates_avg) FROM housing_data)
ORDER BY mortgage_rates_avg DESC;

--4 top 10 highest mortgage rates
SELECT date, mortgage_rates_avg FROM housing_data
ORDER BY mortgage_rates_avg DESC
LIMIT 10;

--5 average mortgage rate by year
SELECT 
	date, 
  	mortgage_rates_avg,
  	ROUND(AVG(mortgage_rates_avg) OVER (
    	PARTITION BY EXTRACT(YEAR FROM date)
	), 2) AS avg_rate_year
FROM housing_data
ORDER BY date;

--6 top 5 years with highest yoy growth, peak inflation years
SELECT year, cpi_growth 
FROM(
	SELECT 
		EXTRACT(YEAR FROM date)::INT AS year,
		ROUND((cpi_index - LAG(cpi_index) OVER (ORDER BY date))
		/ NULLIF(LAG(cpi_index) OVER (ORDER BY date), 0) * 100, 2) AS cpi_growth
	FROM economic_indicators
) sub
WHERE cpi_growth IS NOT NULL
ORDER BY cpi_growth DESC
LIMIT 5;

--7 find top 5 years with highest yoy increase in real gdp
SELECT year, MAX(gdp_growth) AS max_growth
FROM 
	(SELECT 
		EXTRACT(YEAR FROM e1.date)::INT AS year,
		ROUND(
			(e1.gdp_real - e2.gdp_real) / NULLIF(e2.gdp_real, 0) * 100, 2
		) AS gdp_growth
	FROM economic_indicators e1
	JOIN economic_indicators e2
		ON EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date)
		AND EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1
	WHERE e1.gdp_real IS NOT NULL AND e2.gdp_real IS NOT NULL
) sub
GROUP BY year
ORDER BY max_growth DESC
LIMIT 5;

--8 find bottom 5 years with lowest yoy increase in real gdp
SELECT year, MIN(gdp_growth) AS min_growth
FROM 
	(SELECT 
		EXTRACT(YEAR FROM e1.date)::INT AS year,
		ROUND(
			(e1.gdp_real - e2.gdp_real) / NULLIF(e2.gdp_real, 0) * 100, 2
		) AS gdp_growth
	FROM economic_indicators e1
	JOIN economic_indicators e2
		ON EXTRACT(MONTH FROM e1.date) = EXTRACT(MONTH FROM e2.date)
		AND EXTRACT(YEAR FROM e1.date) = EXTRACT(YEAR FROM e2.date) + 1
	WHERE e1.gdp_real IS NOT NULL AND e2.gdp_real IS NOT NULL
) sub
GROUP BY year
ORDER BY min_growth DESC
LIMIT 5;

--9 top 10 months of market_momentum
SELECT date, market_momentum
FROM market_data
WHERE market_momentum IS NOT NULL
ORDER BY market_momentum DESC
LIMIT 10;


--10 best of all to see what's what
--lowest interest, credit exposure, inflation
SELECT 'Mortgage Rate' AS category, date, mortgage_rates_avg AS value
FROM (
  	SELECT date, mortgage_rates_avg
  	FROM housing_data
  	ORDER BY mortgage_rates_avg ASC
  	LIMIT 1
) sub

UNION ALL
--highest credit
SELECT 'Credit Exposure' AS category, date, total_credit_exposure_ratio AS value
FROM (
	SELECT date, total_credit_exposure_ratio
	FROM credit_data
	ORDER BY total_credit_exposure_ratio ASC
	LIMIT 1
) sub

UNION ALL
--housing peak home sales
SELECT 'Home Sales' AS category, date, homes_sold AS value
FROM (
	SELECT date, homes_sold
	FROM housing_data
	WHERE homes_sold IS NOT NULL
	ORDER BY homes_sold DESC
	LIMIT 1
)sub

UNION ALL
--peak inflation
SELECT 'Inflation (CPI)' AS category, date, cpi_index AS value
FROM (
	SELECT date, cpi_index
	FROM economic_indicators
	ORDER BY cpi_index ASC
	LIMIT 1
)sub

UNION ALL
--market highest
SELECT 'S&P 500 (Real)' AS category, date, sp500_index_nominal AS VALUE
FROM (
	SELECT date, sp500_index_nominal
	FROM market_data
	ORDER BY sp500_index_nominal DESC
	LIMIT 1
)sub

UNION ALL
--crypto highest
SELECT 'BTC Price' AS category, date, btc_price as VALUE
FROM (
	SELECT date, btc_price
	FROM cryptocurrency
	ORDER BY btc_price DESC
	LIMIT 1
)sub

UNION ALL
--sentiment highest
SELECT 'Consumer Sentiment' AS category, date, consumer_sentiment AS VALUE
FROM (
	SELECT date, consumer_sentiment
	FROM sentiment_data
	ORDER BY consumer_sentiment DESC
	LIMIT 1
)sub

UNION ALL
--strongest USD
SELECT 'USD Index' AS category, date, usd_fx_index AS value
FROM (
	SELECT date, usd_fx_index
	FROM exchange_rates
	WHERE usd_fx_index IS NOT NULL
	ORDER BY usd_fx_index DESC
	LIMIT 1);

--11 top 5 inflation years based on yoy core_cpi_growth
SELECT DISTINCT ON (year) year, yoy_core_cpi_growth
FROM (
	SELECT
		EXTRACT(YEAR FROM date)::INT AS year,
		ROUND(
			(core_cpi_index - LAG(core_cpi_index, 12) OVER (ORDER BY date)) /
			NULLIF(LAG(core_cpi_index, 12) OVER (ORDER BY date), 0) * 100, 2
		) AS yoy_core_cpi_growth
	FROM economic_indicators
) sub
WHERE yoy_core_cpi_growth IS NOT NULL
ORDER BY year, yoy_core_cpi_growth DESC
LIMIT 5;

--12 see fed_funds_rate during top inflation years which were 1976-1980 and the rolling average
SELECT
	EXTRACT(YEAR FROM date)::INT AS year,
	TO_CHAR(date, 'YYYY-MM') AS month,
	fed_funds_avg,
	ROUND(
		AVG(fed_funds_avg) OVER (ORDER BY date
		ROWS BETWEEN 11 PRECEDING AND CURRENT ROW), 2
	) AS fed_funds_rolling_avg
FROM interest_rates
WHERE EXTRACT(YEAR FROM date)::INT BETWEEN 1978 AND 1980 AND fed_funds_avg IS NOT NULL
ORDER BY date;

--13 mortgage rate trends to yoy CPI growth to see timing lags
SELECT
	TO_CHAR(e.date, 'YYYY-MM') AS MONTH,
	h.mortgage_rates_avg,
	ROUND(
		(e.core_cpi_index - LAG(e.core_cpi_index, 12) OVER (ORDER BY e.date)) /
		NULLIF(LAG(e.core_cpi_index, 12) OVER (ORDER BY e.date), 0) *100, 2
	) AS cpi_yoy_percent
FROM economic_indicators e
JOIN housing_data h ON e.date = h.date
WHERE h.mortgage_rates_avg IS NOT NULL AND e.core_cpi_index IS NOT NULL
ORDER BY e.date;

--14 vix mothly average vs. fed funds rate 
WITH fed_funds_rate_change AS (
	SELECT date, fed_funds_avg,
		ROUND(fed_funds_avg - LAG(fed_funds_avg) OVER (ORDER BY date), 2) AS fed_funds_rate_change
	FROM interest_rates
),
vix_vs_fed_rate AS (
	SELECT r.date, r.fed_funds_avg, r.fed_funds_rate_change, s.vix_index_avg
	FROM fed_funds_rate_change r
	JOIN sentiment_data s ON r.date = s.date
)
SELECT *
FROM vix_vs_fed_rate
WHERE fed_funds_rate_change IS NOT NULL
ORDER BY date;

-- 15 bottom 10 years of consumer sentiment and business sentiment
SELECT date, consumer_sentiment, business_sentiment
FROM sentiment_data
WHERE consumer_sentiment IS NOT NULL AND business_sentiment IS NOT NULL
ORDER BY consumer_sentiment
LIMIT 10;

--top 10 years of consumer sentiment and business sentiment
SELECT date, consumer_sentiment, business_sentiment
FROM sentiment_data
WHERE consumer_sentiment IS NOT NULL AND business_sentiment IS NOT NULL
ORDER BY consumer_sentiment DESC
LIMIT 10;

--16 top 10 years of consumer sentiment, business sentiment and fed_funds_avg
SELECT s.date, s.consumer_sentiment, s.business_sentiment, i.fed_funds_avg
FROM sentiment_data s
JOIN interest_rates i ON s.date = i.date
WHERE consumer_sentiment IS NOT NULL AND business_sentiment IS NOT NULL
ORDER BY consumer_sentiment DESC
LIMIT 10;

--17 checking some calculated fields to make sure calcs are correct
SELECT date,
	consumer_credit_outstanding,
	total_bank_credit,
	consumer_credit_exposure_ratio,
	ROUND(consumer_credit_outstanding / total_bank_credit, 2) AS expected_ratio
FROM credit_data
WHERE consumer_credit_exposure_ratio IS DISTINCT FROM ROUND(
	consumer_credit_outstanding / total_bank_credit, 2)
LIMIT 5;


SELECT date,
	real_estate_credit_outstanding,
	total_bank_credit,
	real_estate_exposure_ratio,
	ROUND(real_estate_credit_outstanding / total_bank_credit, 2) AS expected_ratio
FROM credit_data
WHERE real_estate_exposure_ratio IS DISTINCT FROM ROUND(
	real_estate_credit_outstanding / total_bank_credit, 2)
LIMIT 5;


SELECT date,
	total_credit_outstanding,
	total_bank_credit,
	total_credit_exposure_ratio,
	ROUND(total_credit_outstanding / total_bank_credit, 2) AS expected_ratio
FROM credit_data
WHERE total_credit_exposure_ratio IS DISTINCT FROM ROUND(
	total_credit_outstanding / total_bank_credit, 2)
LIMIT 5;


SELECT date,
	btc_circulating_supply,
	btc_price,
	ROUND(btc_market_cap / btc_price, 2) AS expected
FROM cryptocurrency
WHERE btc_circulating_supply IS DISTINCT FROM ROUND(
	btc_market_cap / btc_price, 2)
LIMIT 5;


SELECT date,
	eth_circulating_supply,
	eth_price,
	ROUND(eth_market_cap / eth_price, 2) AS expected
FROM cryptocurrency
WHERE eth_circulating_supply IS DISTINCT FROM ROUND(
	eth_market_cap / eth_price, 2)
LIMIT 5;


SELECT date,
	gdp_real,
	gdp,
	ROUND(gdp / cpi_index, 2) AS expected
FROM economic_indicators
WHERE gdp_real IS DISTINCT FROM ROUND(
	gdp / cpi_index, 2)
LIMIT 5;


SELECT e1.date,
	e1.core_inflation_yoy,
	e1.core_cpi_index,
	e2.core_cpi_index,
	e2.core_cpi_index AS cpi_12mo_avg,
	ROUND((e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2) AS expected
FROM economic_indicators e1
JOIN economic_indicators e2
	ON e1.date = e2.date + INTERVAL '12 months'
WHERE e1.core_inflation_yoy IS DISTINCT FROM ROUND((e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2)
LIMIT 5;


SELECT e1.date,
	e1.inflation_yoy,
	e1.cpi_index,
	e2.cpi_index,
	e2.cpi_index AS cpi_12mo_avg,
	ROUND((e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2) AS expected
FROM economic_indicators e1
JOIN economic_indicators e2
	ON e1.date = e2.date + INTERVAL '12 months'
WHERE e1.inflation_yoy IS DISTINCT FROM ROUND((e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2)
LIMIT 5;


SELECT e1.date,
	e1.core_inflation_mom,
    e1.core_cpi_index,
    e2.core_cpi_index AS core_cpi_1mo_ago,
    ROUND((e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2) AS expected
FROM economic_indicators e1
JOIN economic_indicators e2
	ON e1.date = e2.date + INTERVAL '1 month'
WHERE e1.core_inflation_mom IS DISTINCT FROM ROUND((e1.core_cpi_index - e2.core_cpi_index) / e2.core_cpi_index * 100, 2)
LIMIT 5;


SELECT e1.date,
	e1.inflation_mom,
    e1.cpi_index,
    e2.cpi_index AS core_cpi_1mo_ago,
    ROUND((e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2) AS expected
FROM economic_indicators e1
JOIN economic_indicators e2
	ON e1.date = e2.date + INTERVAL '1 month'
WHERE e1.inflation_mom IS DISTINCT FROM ROUND((e1.cpi_index - e2.cpi_index) / e2.cpi_index * 100, 2)
LIMIT 5;


SELECT date,
	price_to_mortgage_rate_ratio,
	housing_price_index,
	ROUND(housing_price_index / mortgage_rates_avg, 2) AS expected
FROM housing_data
WHERE price_to_mortgage_rate_ratio IS DISTINCT FROM ROUND(
	housing_price_index / mortgage_rates_avg, 2)
LIMIT 5;

--compare tsec with 5 top indicators
SELECT i.date,
		i.tsec_10yr_avg,
		h.mortgage_rates_avg,
		i.policy_stance_rate,
		e.ppi_index,
		i.tbill_3mo,
		i.moody_aaa,
		e.gdp_real
FROM interest_rates i
JOIN housing_data h ON i.date = h.date
JOIN economic_indicators e ON i.date = e.date
WHERE i.date >= '2020-01-01'
ORDER BY i.date;

	

	