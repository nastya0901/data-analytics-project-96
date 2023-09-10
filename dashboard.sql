with tab as (
    select
        s.visitor_id,
        visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign as utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id,
        rank() over (partition by s.visitor_id order by visit_date desc) as rnk
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id
    where
        medium in (
            'cpc', 'cpm', 'cpa', 'youtube', 'cpp',
            'tg'
        )
),
tab1 as (
    select
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id
    from tab
    where rnk = 1
),
ads as (
    select
        to_char(campaign_date, 'YYYY-MM-DD') as cd,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by 1, 2, 3, 4
    union
    select
        to_char(campaign_date, 'YYYY-MM-DD') as cd,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by 1, 2, 3, 4
),
dashboard  as (
select
    cast(to_char(visit_date, 'YYYY-MM-DD') as date) as visit_date,
    extract(isodow from visit_date) as visit_weekday, 
    tab1.utm_source,
    tab1.utm_medium,
    tab1.utm_campaign,
    ads.total_cost,
    count(*) as visitors_count,
    count(lead_id) as lead_count,
    count(case when status_id = 142 then 1 end) as purchases_count,
    sum(case when status_id = 142 then amount end) as revenue
from tab1
left join ads
    on
        to_char(tab1.visit_date, 'YYYY-MM-DD') = ads.cd
        and tab1.utm_source = ads.utm_source
        and tab1.utm_medium = ads.utm_medium
        and tab1.utm_campaign = ads.utm_campaign
group by 1, 2, 3, 4, 5, 6
)
/*- 1 количество посетителей на сайте
select visit_date,
sum (visitors_count)
from dashboard
group by 1;
-- 2 количество посетителей из разных источников по дням недели
select visit_weekday,
utm_source,
sum (visitors_count)
from dashboard
group by 1,2
-- 3 количество лидов по днм недели
select visit_weekday,
sum (lead_count)
from dashboard
group by 1;
--4 конверсия из посетителй в лиды и из лидов в оплаты
select utm_source,
round(sum (lead_count)/sum (visitors_count)*100.00,2) as conv1,
case when sum (coalesce(lead_count,0)) = 0 then 0.00 else round(sum (coalesce(purchases_count,0))/sum (coalesce(lead_count,0))*100.00,2) end as conv2
from dashboard
group by 1;
--5 траты по разным каналам в динамике
select case when extract (day from cast(visit_date as date)) between 1 and 10 then 1
when extract (day from cast(visit_date as date)) between 11 and 20 then 2
else 3 end as MonthDecade,
sum(total_cost),utm_source
from dashboard
group by 1,3
having sum(total_cost)>0;
--6 окупаемость каналов
select
    utm_source,
    sum(total_cost) as total_cost,
    sum(revenue) as revenue
from dashboard
group by 1
having sum(total_cost)>0 or sum(revenue)>0;

--7  сновные метрики по дням:
select
cast(visit_date as date), 
case when sum (coalesce(visitors_count,0)) = 0 then 0.00 else round(sum(coalesce(total_cost,0))/sum(coalesce(visitors_count,0)),2) end as cpu,
case when sum (coalesce(lead_count,0)) = 0 then 0.00 else round(sum(coalesce(total_cost,0)) /sum(coalesce(lead_count,0)),2) end as cpl,
case when sum (coalesce(purchases_count,0)) = 0 then 0.00 else round(sum( coalesce(total_cost,0))/sum(coalesce(purchases_count,0)),2) end as cppu,
case when sum (coalesce(total_cost,0)) = 0 then 0.00 else round(sum(coalesce(revenue,0) - coalesce(total_cost,0)) / sum(coalesce(total_cost,0)),2) * 100.00 end as roi
from dashboard
where cast(visit_date as date) between '20230601' and '20230630'
group by 1;

--8  основные метрики за период:
select
case when sum (coalesce(visitors_count,0)) = 0 then 0.00 else round(sum(coalesce(total_cost,0))/sum(coalesce(visitors_count,0)),2) end as cpu,
case when sum (coalesce(lead_count,0)) = 0 then 0.00 else round(sum(coalesce(total_cost,0)) /sum(coalesce(lead_count,0)),2) end as cpl,
case when sum (coalesce(purchases_count,0)) = 0 then 0.00 else round(sum( coalesce(total_cost,0))/sum(coalesce(purchases_count,0)),2) end as cppu,
case when sum (coalesce(total_cost,0)) = 0 then 0.00 else round(sum(coalesce(revenue,0) - coalesce(total_cost,0)) / sum(coalesce(total_cost,0)),2) * 100.00 end as roi
from dashboard
where cast(visit_date as date) between '20230601' and '20230630'
*/


     
    