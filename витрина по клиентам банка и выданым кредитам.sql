select  
    id_client
    , b.name_city
    -- название города из таблицы регионов
    , case 
        when (gender) = 'M' 
        then 1 
        else 0 
        end as nflag_gender
        -- флаг пола, 1 мужской, 0 женский
    , age
    , first_time
    , case 
        when (cellphone) is not null 
        then 1 
        else 0 
        end as nflag_cellphone
        -- флаг наличия телефона
    , is_active
    , cl_segm
    , amt_loan
    , date_loan
    , credit_type
    , sum(amt_loan) over (partition by name_city) as sum_city
    -- сумма кредитов в городе 
    , amt_loan/sum(amt_loan) over (partition by name_city)::float as share_loan_city
    -- доля кредита среди кредитов по городу
    , sum(amt_loan) over (partition by credit_type) as sum_type
    -- сумма кредитов по типу
    , amt_loan/sum(amt_loan) over (partition by credit_type)::float as share_type
    -- доля кредита среди типа кредита
    , sum(amt_loan) over (partition by name_city, credit_type) as sum_city_type
    -- сумма кредиов по типу в одном городе 
    , amt_loan/sum(amt_loan) over (partition by name_city, credit_type)::float as share_city_type
    -- доля кредита среди такого типа в одном городе 
    , count(amt_loan) over (partition by name_city) as cnt_loan_city
    -- количество кредитов в одном городе 
    , count(amt_loan) over (partition by credit_type) as cnt_loan_type
    -- количество кредитов одного типа
    , count(amt_loan) over (partition by credit_type, name_city) as cnt_loan_type_city
    -- количество кредитов одного типа в одном городе 
             from skybank.late_collection_clients a 
            --  оновная таблица
             left join skybank.region_dict b 
            --  таблица с названием города 
             on a.id_city = b.id_city
             
    
    --  limit 100