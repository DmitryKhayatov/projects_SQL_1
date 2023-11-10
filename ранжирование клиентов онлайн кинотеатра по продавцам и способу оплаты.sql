select name_partner
    , is_trial
    , count (*)
from -- подзапрос 
(select  is_trial
    , partner
    , name_partner
    , user_id, purchase_id
    , date_purchase
    , row_number() over (order by date_purchase asc) rn_all
-- ранг покупки среди всех покупок по дате покупки. 
    , row_number() over (partition by user_id order by date_purchase asc) row_user
-- окно по столбцу user_id и сортировка значения по дате покупки в порядке возрастания в границах айди юзера. 
        from skycinema.client_sign_up a
            join skycinema.partner_dict b 
            on a.partner = b.id_partner
             -- название партнера
            ) as t 
        where row_user = 1 
        group by name_partner, is_trial
