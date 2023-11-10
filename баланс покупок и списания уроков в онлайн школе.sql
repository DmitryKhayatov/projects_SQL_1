-- Дата первого платежа 1 
WITH first_payments as (
	SELECT user_id
	, min (transaction_datetime_cut) as first_payment_date
		FROM  (select *
			, date (transaction_datetime) as transaction_datetime_cut
			FROM skyeng_db.payments) t 
			WHERE status_name = 'success'
			and date_trunc ('year', transaction_datetime_cut) = '2016-01-01'
			group by user_id
				)
				,
-- Уникальные даты из таблицы уроков 2 
all_dates as (
	SELECT distinct date (class_start_datetime) as dt
		FROM skyeng_db.classes
		 WHERE date_trunc ('year', class_start_datetime) = '2016-01-01'
-- 		 and user_id = 325348
		)
		,
-- Синтетический календарь на гипотезе, что в уроках есть все даты 2016 года. Берется дата из всех дат и к ней притягивается юзер айди из таблицы оплат. 3 
all_dates_by_user as (
	SELECT dt, t2.user_id
		from all_dates t1 
			left JOIN first_payments t2 
			on dt>=first_payment_date
				order BY user_id , dt 
					  )
					  ,
-- Покупки уроков по датам 4 
payment_by_dates as (
	SELECT 
		user_id
		, payment_date
		, transaction_cnt
			FROM (SELECT user_id
			, payment_date
			, Sum (classes) over (partition by user_id, payment_date) as transaction_cnt
			, row_number () over (PARTITION by user_id, payment_date) as number_payment
				FROM
					(SELECT user_id
					, date (transaction_datetime) as payment_date
					, classes
						from skyeng_db.payments
						where date_trunc ('year', transaction_datetime) = '2016-01-01'
						and status_name = 'success'
							group by user_id, payment_date, classes
							order by user_id, payment_date) t 
							GROUP by user_id, payment_date, classes) t1
								WHERE number_payment = 1
				)
				,	
--Сумма покупки по юзеру 5
payment_sum as (
	SELECT t1.user_id
	, dt
	, COALESCE (transaction_cnt, 0) as transaction_cnt
	, COALESCE (sum (transaction_cnt) OVER (PARTITION by t1.user_id), 0) as transaction_sum
		FROM all_dates_by_user t1
			LEFT JOIN payment_by_dates t2
			on t1.user_id = t2.user_id
			and dt = payment_date
			GROUP by t1.user_id, dt , transaction_cnt
			order by  user_id, dt 
							)
							,
-- Сколько списано в день с юзера 6
classes_by_dates as (
	SELECT user_id
	, class_date
	, count (*) over (partition by user_id, class_date)*-1 as classes_cnt
		FROM (
			SELECT user_id, date (class_start_datetime) as class_date
				FROM skyeng_db.classes
					WHERE date_trunc ('year', class_start_datetime)='2016-01-01'
					AND class_type <> 'trial'
					AND class_status in ('success','failed_by_student')
					)t1
					)
					, 
-- сумма списаных уроков 7
classes_sum as (
	SELECT t1.user_id
		, dt
		, COALESCE (classes_cnt, 0) as classes_cnt
		, COALESCE (sum (classes_cnt) over (partition by t1.user_id), 0) classes_sum
			FROM all_dates_by_user t1
			left join classes_by_dates t2
			on t1.user_id = t2.user_id
			and dt=class_date
				order by t1.user_id, dt 
				)
				,
-- Баланс по студенту и датам 8
balances as (
SELECT t1.user_id
	, t1.dt
	, transaction_cnt
	, transaction_sum
	, classes_cnt
	, classes_sum
	, (transaction_sum + classes_sum) as balance
		FROM payment_sum t1
			JOIN classes_sum t2
			ON t1.user_id = t2.user_id
			AND t1.dt = t2.dt
				ORDER by dt, user_id
			)
-- Динамика баланса уроков  по дате 9
SELECT distinct dt
	, sum (transaction_cnt) over (partition by dt) as transaction_cnt
-- 	, sum (transaction_sum) OVER (PARTITION BY dt) as transaction_sum
	, sum (classes_cnt) OVER (PARTITION BY dt) as classes_cnt
-- 	, sum (classes_sum) OVER (PARTITION BY dt) as classes_sum
	, sum (balance) OVER (PARTITION BY dt) as balance
FROM balances
GROUP BY dt, transaction_cnt, transaction_sum, classes_cnt, classes_sum, balance
ORDER by dt
