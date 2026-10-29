-- 01_basics: create a MergeTree table, insert rows, aggregate

CREATE DATABASE IF NOT EXISTS learn;

CREATE TABLE IF NOT EXISTS learn.events
(
    ts      DateTime,
    user_id UInt32,
    event   LowCardinality(String),
    value   Float64
)
ENGINE = MergeTree
ORDER BY (event, ts);

TRUNCATE TABLE learn.events;

-- Generate 1M synthetic rows
INSERT INTO learn.events
SELECT
    now() - toIntervalSecond(number),
    number % 1000,
    ['click', 'view', 'purchase'][number % 3 + 1],
    rand() % 100 / 10
FROM numbers(1000000);

SELECT event, count() AS n, round(avg(value), 2) AS avg_value
FROM learn.events
GROUP BY event
ORDER BY n DESC;
