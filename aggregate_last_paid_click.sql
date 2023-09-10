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
)

select
    to_char(visit_date, 'YYYY-MM-DD') as visit_date,
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
group by 1, 2, 3, 4, 5
order by
    sum(case when status_id = 142 then amount else 0 end) desc,
    visit_date, visitors_count desc,
    utm_source asc, utm_medium asc, utm_campaign asc;
     
    