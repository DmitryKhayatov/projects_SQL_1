select  name_partner
        , sum (case when row_user = 1 then 1 else 0 end):: float as "1_purchases" -- количество 1 покупки 
        , sum (case when row_user = 2 then 1 else 0 end) / sum (case when row_user = 1 then 1 else 0 end) :: float as "2_purchases"
        , sum (case when row_user = 3 then 1 else 0 end) / sum (case when row_user = 1 then 1 else 0 end) :: float as "3_purchases"
        , sum (case when row_user = 4 then 1 else 0 end) / sum (case when row_user = 1 then 1 else 0 end) :: float as "4_purchases"
        , sum (case when row_user = 5 then 1 else 0 end) / sum (case when row_user = 1 then 1 else 0 end) :: float as "5_purchases"
        , sum (case when row_user = 6 then 1 else 0 end) / sum (case when row_user = 1 then 1 else 0 end) :: float as "6_purchases"
        -- в таблице максимально 6 покупок на 1 юзера. До целых процентов округлять не стал. 
        -- Глаз режет например Альфа банк откругляет с 1,7 до 2, а даже без расчета видно. что это не верно.
    from 
    -- подзапрос присваюващий порядковый номер (ранг) покупки на юзера 
    (select  
        is_trial
        , partner
        , name_partner
        , user_id, purchase_id
        , date_purchase
        , row_number() over (order by date_purchase asc) rn_all -- порядковый номер (ранг) покупки во всей таблице
        , row_number() over (partition by user_id order by date_purchase asc) row_user
            from skycinema.client_sign_up a
                join skycinema.partner_dict b 
                on a.partner = b.id_partner) as t 
                	group by name_partner 
                		order by name_partner