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
        on s.visitor_id = l.visitor_id and s.visit_date < l.created_at
    where
        medium in (
            'cpc', 'cpm', 'cpa', 'youtube', 'cpp',
            'tg', 'social'
        )
)
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
order by visit_date, utm_source, utm_medium, utm_campaign;