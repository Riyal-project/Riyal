-- Realistic mock amounts for People and Utilities. Idempotent: rows are
-- matched by merchant (and, for utilities, by bill order newest -> oldest),
-- so it works whatever dates the relative seeds landed on.

-- People: every payee is paid the same amount each month (the detection
-- engine needs same-amount matches) and every amount is >= 1,500 SAR.
update mock_transactions
set amount = case merchant_name
  when 'TRANSFER TO GARDENER - YOUSEF' then 1500
  when 'TUTOR PAYMENT - MR AHMAD'      then 1700
  when 'HOUSEKEEPER SALARY - FATIMA'   then 1800
  when 'TRANSFER TO DRIVER - AHMED'    then 2200
  when 'TRANSFER TO DRIVER - KHALID'   then 2600
  when 'NANNY SALARY - MARIA'          then 3000
end
where merchant_name in (
  'TRANSFER TO GARDENER - YOUSEF', 'TUTOR PAYMENT - MR AHMAD',
  'HOUSEKEEPER SALARY - FATIMA', 'TRANSFER TO DRIVER - AHMED',
  'TRANSFER TO DRIVER - KHALID', 'NANNY SALARY - MARIA'
);

-- Utilities: usage-based, so bills vary. The window is Jun-Sep (summer),
-- ramping up toward the peak. The newest bill of each series is a spike
-- over the average of the three before it (electricity +52% -> red,
-- water +30% -> yellow) so the anomaly flags can be tested. Amounts stay
-- inside the +/-40% band the recurring-detection engine allows for
-- utilities. STC internet (fixed price) and Zain are not touched.
update mock_transactions t
set amount = v.amount
from (
  select id, merchant_name,
         row_number() over (
           partition by merchant_name order by transaction_date desc
         ) as rn
  from mock_transactions
  where merchant_name in (
    'SAUDI ELECTRICITY COMPANY - SEC BILL', 'NATIONAL WATER COMPANY BILL'
  )
) r
join (values
  ('SAUDI ELECTRICITY COMPANY - SEC BILL', 1, 1189),
  ('SAUDI ELECTRICITY COMPANY - SEC BILL', 2,  851),
  ('SAUDI ELECTRICITY COMPANY - SEC BILL', 3,  788),
  ('SAUDI ELECTRICITY COMPANY - SEC BILL', 4,  704),
  ('NATIONAL WATER COMPANY BILL', 1, 234),
  ('NATIONAL WATER COMPANY BILL', 2, 182),
  ('NATIONAL WATER COMPANY BILL', 3, 188),
  ('NATIONAL WATER COMPANY BILL', 4, 172)
) as v(merchant_name, rn, amount)
  on v.merchant_name = r.merchant_name and v.rn = r.rn
where t.id = r.id;
