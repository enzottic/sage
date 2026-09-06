# Stats design research — September 6, 2026

Reviewed 32 Appllama screen images covering finance dashboards, budget summaries,
analytics, empty states, and related charts. Reference images were downloaded to
`/tmp/sage-stats-research`; durable screen references below can refresh them.

Strongest references:
- Buddy `936422955/oth_kbpv2`: total above cumulative chart; neutral average and compact legend.
- Buddy `936422955/oth_rb8tn`: same chart with day selection and zero-data treatment.
- Buddy `936422955/oth_zorva`: explicit month with adjacent previous/next chevrons.
- Buddy `936422955/oth_0a8iv`: month remains the context above spending breakdown.
- EveryDollar `942571931/oth_377ww`: ranked rows with aligned amounts and unobtrusive separators.
- EveryDollar `942571931/oth_5ep48`: equally weighted icon-led explanatory rows.
- TravelSpend `1434284824/oth_kt7o1`: summary first, filters adjacent to chart, detailed breakdown below.
- TravelSpend `1434284824/oth_a1630`: plain-language explanation of a derived metric.

Sage adaptation: existing native toolbar chevrons and month picker; monthly total
and cumulative chart first, same-weight factual insights, top tags, then historical
bars. Retain Sage colors and 15-point card corners. Grey dashed historical average
is distinguishable without relying only on color. No forecasts. Weekly breakdown
is scoped to the selected month; monthly bars select the month for the entire view.
