with tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number()
        over (partition by s.visitor_id order by s.visit_date desc)
        as rnk
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date < l.created_at
    where
        s.medium in (
            'cpc', 'cpm', 'cpa', 'youtube', 'cpp',
            'tg', 'social'
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
    union all
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
    tab1.utm_source,
    tab1.utm_medium,
    tab1.utm_campaign,
    ads.total_cost,
    to_char(tab1.visit_date, 'YYYY-MM-DD') as visit_date,
    count(tab1.visitor_id) as visitors_count,
    count(tab1.lead_id) as leads_count,
    count(case when tab1.status_id = 142 then 1 end) as purchases_count,
    sum(case when tab1.status_id = 142 then tab1.amount end) as revenue
from tab1
left join ads
    on
        to_char(tab1.visit_date, 'YYYY-MM-DD') = ads.cd
        and tab1.utm_source = ads.utm_source
        and tab1.utm_medium = ads.utm_medium
        and tab1.utm_campaign = ads.utm_campaign
group by 1, 2, 3, 4, 5
order by
    9 desc,
    5, 6 desc,
    1, 2, 3;
