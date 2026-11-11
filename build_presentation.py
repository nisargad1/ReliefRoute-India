import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

def create_presentation():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_slide_layout = prs.slide_layouts[6]

    # Color Palette Definitions
    DARK_BG = RGBColor(11, 25, 44)        # #0B192C Deep Navy
    DARK_CARD = RGBColor(21, 44, 76)      # #152C4C Dark Card
    LIGHT_BG = RGBColor(248, 250, 252)    # #F8FAFC Slate 50
    WHITE = RGBColor(255, 255, 255)
    SLATE_900 = RGBColor(15, 23, 42)      # #0F172A Dark Charcoal
    SLATE_700 = RGBColor(51, 65, 85)      # #334155
    SLATE_500 = RGBColor(100, 116, 139)   # #64748B Muted
    BORDER_COLOR = RGBColor(226, 232, 240) # #E2E8F0
    
    PRIMARY_BLUE = RGBColor(14, 116, 144)  # Cyan/Teal #0E7490
    NAVY_BLUE = RGBColor(30, 58, 138)     # Deep Blue #1E3A8A
    ORANGE_ALERT = RGBColor(234, 88, 12)  # Hazard Orange #EA580C
    EMERALD_GREEN = RGBColor(16, 185, 129)# Safe Emerald #10B981
    ROSE_RED = RGBColor(225, 29, 72)      # Danger Rose #E11D48
    AMBER_YELLOW = RGBColor(217, 119, 6)  # Warning Amber #D97706
    PURPLE_ACC = RGBColor(126, 34, 206)   # #7E22CE

    image_dir = r"C:\Users\Nisarga\Downloads\ReliefRoute-India-v2\ReliefRoute-India\docs\images"
    img_hero = os.path.join(image_dir, "hero_telemetry.jpg")
    img_flood = os.path.join(image_dir, "flooded_highway.jpg")
    img_convoy = os.path.join(image_dir, "safe_convoy.jpg")

    def add_bg(slide, color):
        bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, prs.slide_width, prs.slide_height)
        bg.fill.solid()
        bg.fill.fore_color.rgb = color
        bg.line.fill.background()
        return bg

    def add_header(slide, tag_text, title_text, subtitle_text=None, tag_color=PRIMARY_BLUE):
        # Category Tag Pill
        tag_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.4), Inches(8), Inches(0.4))
        tf_tag = tag_box.text_frame
        tf_tag.word_wrap = True
        tf_tag.margin_left = tf_tag.margin_top = tf_tag.margin_right = tf_tag.margin_bottom = 0
        p_tag = tf_tag.paragraphs[0]
        p_tag.text = tag_text.upper()
        p_tag.font.size = Pt(11)
        p_tag.font.bold = True
        p_tag.font.color.rgb = tag_color

        # Title
        title_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.75), Inches(11.5), Inches(0.65))
        tf_title = title_box.text_frame
        tf_title.word_wrap = True
        tf_title.margin_left = tf_title.margin_top = tf_title.margin_right = tf_title.margin_bottom = 0
        p_title = tf_title.paragraphs[0]
        p_title.text = title_text
        p_title.font.size = Pt(24)
        p_title.font.bold = True
        p_title.font.color.rgb = SLATE_900

        # Subtitle
        if subtitle_text:
            sub_box = slide.shapes.add_textbox(Inches(0.8), Inches(1.35), Inches(11.5), Inches(0.4))
            tf_sub = sub_box.text_frame
            tf_sub.word_wrap = True
            tf_sub.margin_left = tf_sub.margin_top = tf_sub.margin_right = tf_sub.margin_bottom = 0
            p_sub = tf_sub.paragraphs[0]
            p_sub.text = subtitle_text
            p_sub.font.size = Pt(13)
            p_sub.font.color.rgb = SLATE_500

    def add_card(slide, left, top, width, height, bg_color=WHITE, border_color=BORDER_COLOR):
        shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, width, height)
        shape.fill.solid()
        shape.fill.fore_color.rgb = bg_color
        if border_color:
            shape.line.color.rgb = border_color
            shape.line.width = Pt(1.2)
        else:
            shape.line.fill.background()
        return shape

    # =========================================================================
    # SLIDE 1: TITLE SLIDE (Dark Mode Hero)
    # =========================================================================
    s1 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s1, DARK_BG)

    # Accent decorative glow bar
    bar = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(1.2), Inches(0.12), Inches(4.8))
    bar.fill.solid()
    bar.fill.fore_color.rgb = ORANGE_ALERT
    bar.line.fill.background()

    # Title text frame
    t_box = s1.shapes.add_textbox(Inches(1.2), Inches(1.2), Inches(6.2), Inches(4.8))
    tf1 = t_box.text_frame
    tf1.word_wrap = True
    tf1.margin_left = tf1.margin_top = tf1.margin_right = tf1.margin_bottom = 0

    p_badge = tf1.paragraphs[0]
    p_badge.text = "ACADEMIC MINI PROJECT  •  DISASTER RESPONSE LOGISTICS"
    p_badge.font.size = Pt(11)
    p_badge.font.bold = True
    p_badge.font.color.rgb = ORANGE_ALERT
    p_badge.space_after = Pt(14)

    p_main = tf1.add_paragraph()
    p_main.text = "ReliefRoute India v2"
    p_main.font.size = Pt(36)
    p_main.font.bold = True
    p_main.font.color.rgb = WHITE
    p_main.space_after = Pt(10)

    p_sub = tf1.add_paragraph()
    p_sub.text = "Dynamic Humanitarian Supply-Chain Router &\nRisk-Aware Fleet Optimization for India"
    p_sub.font.size = Pt(18)
    p_sub.font.color.rgb = RGBColor(186, 215, 233)
    p_sub.space_after = Pt(28)

    p_desc = tf1.add_paragraph()
    p_desc.text = "An interactive GIS decision-support framework that bridges live hazard feeds (rain, floods, quakes) with Dijkstra shortest-path routing, transportation linear programming, and convoy VRP."
    p_desc.font.size = Pt(12)
    p_desc.font.color.rgb = RGBColor(148, 163, 184)
    p_desc.space_after = Pt(30)

    p_meta = tf1.add_paragraph()
    p_meta.text = "Developed by: Nisarga Devaraj (github.com/nisargad1)\nTech Stack: R 4.1+, Shiny, Leaflet, sf, igraph, lpSolve, OSRM\nNovember 2026  •  Open-Source (MIT License)"
    p_meta.font.size = Pt(11)
    p_meta.font.bold = True
    p_meta.font.color.rgb = RGBColor(226, 232, 240)

    # Hero Image on Right Side
    if os.path.exists(img_hero):
        hero_card = add_card(s1, Inches(7.7), Inches(1.2), Inches(4.8), Inches(5.1), DARK_CARD, RGBColor(30, 62, 98))
        s1.shapes.add_picture(img_hero, Inches(7.8), Inches(1.3), Inches(4.6), Inches(3.8))
        
        caption_box = s1.shapes.add_textbox(Inches(7.8), Inches(5.2), Inches(4.6), Inches(0.9))
        tf_cap = caption_box.text_frame
        tf_cap.word_wrap = True
        p_cap = tf_cap.paragraphs[0]
        p_cap.text = "AI/GIS-Assisted Convoy Navigation: Real-time risk avoidance routing relief trucks through India's Western Ghats & flood plains."
        p_cap.font.size = Pt(10)
        p_cap.font.color.rgb = RGBColor(148, 163, 184)

    # =========================================================================
    # SLIDE 2: THE PROBLEM STATEMENT
    # =========================================================================
    s2 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s2, LIGHT_BG)
    add_header(s2, "Problem Statement & Real-World Motivation", 
               "Why Traditional Commercial GPS Fails in Disaster Logistics",
               "Humanitarian supply chains face extreme uncertainty, shifting danger zones, and high life-safety stakes.")

    # Left Column: 3 Critical Failure Modes
    cards_data = [
        ("1. Divergent Objectives: Fastest vs. Survivable", 
         "Commercial GPS (Google Maps, OSRM) strictly minimizes travel time or tolls. In crises (Kerala floods, Cyclone Fani), the 'fastest' highway frequently leads into submerged bridges, washouts, and active landslides.",
         ROSE_RED),
        ("2. Information Delay & Fragmentation", 
         "Official bulletins (NDMA, SDMA, IMD rain alerts) are published as PDFs, radio broadcasts, or static map viewers. They are completely un-routable and disconnected from vehicle dispatch engines.",
         AMBER_YELLOW),
        ("3. High Stakes & Decoupled Decisions", 
         "Logistics accounts for 60%–80% of total disaster relief expenditure (Van Wassenhove, 2006). Which hub serves which camp and which route trucks take are coupled; closing one road disrupts the entire national plan.",
         NAVY_BLUE)
    ]

    for idx, (head, body, acc_col) in enumerate(cards_data):
        y_pos = Inches(1.85 + idx * 1.65)
        card = add_card(s2, Inches(0.8), y_pos, Inches(6.8), Inches(1.48))
        
        # Pill
        stripe = s2.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), y_pos, Inches(0.1), Inches(1.48))
        stripe.fill.solid()
        stripe.fill.fore_color.rgb = acc_col
        stripe.line.fill.background()

        tb = s2.shapes.add_textbox(Inches(1.05), y_pos + Inches(0.12), Inches(6.4), Inches(1.25))
        tf = tb.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
        p1 = tf.paragraphs[0]
        p1.text = head
        p1.font.size = Pt(13)
        p1.font.bold = True
        p1.font.color.rgb = SLATE_900
        p1.space_after = Pt(4)
        
        p2 = tf.add_paragraph()
        p2.text = body
        p2.font.size = Pt(10.5)
        p2.font.color.rgb = SLATE_700

    # Right Column: Visual Photo & Stat Callout
    if os.path.exists(img_flood):
        card_pic = add_card(s2, Inches(7.8), Inches(1.85), Inches(4.7), Inches(3.3))
        s2.shapes.add_picture(img_flood, Inches(7.9), Inches(1.95), Inches(4.5), Inches(2.7))
        cap_b = s2.shapes.add_textbox(Inches(7.9), Inches(4.7), Inches(4.5), Inches(0.4))
        p_c = cap_b.text_frame.paragraphs[0]
        p_c.text = "Real-World Hazard: Monsoon flooding cutting off Indian highways."
        p_c.font.size = Pt(9.5)
        p_c.font.color.rgb = SLATE_500

    # Key Stat Callout Card
    stat_card = add_card(s2, Inches(7.8), Inches(5.35), Inches(4.7), Inches(1.6), RGBColor(254, 242, 242), RGBColor(254, 205, 211))
    tb_st = s2.shapes.add_textbox(Inches(8.0), Inches(5.45), Inches(4.3), Inches(1.4))
    tf_st = tb_st.text_frame
    tf_st.word_wrap = True
    p_st1 = tf_st.paragraphs[0]
    p_st1.text = "60% – 80%"
    p_st1.font.size = Pt(24)
    p_st1.font.bold = True
    p_st1.font.color.rgb = ROSE_RED
    p_st2 = tf_st.add_paragraph()
    p_st2.text = "Of all disaster relief operational spending is consumed by transportation and logistics. Every stranded convoy represents lost human lives."
    p_st2.font.size = Pt(10.5)
    p_st2.font.color.rgb = SLATE_900

    # =========================================================================
    # SLIDE 3: EXISTING SOLUTIONS VS OUR SOLUTION
    # =========================================================================
    s3 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s3, LIGHT_BG)
    add_header(s3, "Competitive Landscape & The Research Gap", 
               "Existing Solutions vs. ReliefRoute India v2",
               "How our research bridges the structural gaps in current commercial and disaster navigation tools.")

    solutions = [
        ("Google Maps / Routes API", 
         "Commercial Leader",
         [("Hazard Avoidance", "None (Only tolls, highways, ferries)"),
          ("Custom Danger Polygons", "Not supported by API"),
          ("Continuous Risk Metric", "Pure travel-time / distance cost"),
          ("Multi-Hub Fleet Allocation", "None (Single point-to-point)"),
          ("Open-Source & Teachable", "Proprietary, paid API")],
         BORDER_COLOR),
        ("OSRM / OpenRouteService", 
         "Open-Source Routing",
         [("Hazard Avoidance", "Binary avoidance in ORS; clips edges"),
          ("Custom Danger Polygons", "Slow / requires pre-processing"),
          ("Continuous Risk Metric", "Limited / experimental custom models"),
          ("Multi-Hub Fleet Allocation", "No depot balancing or LP"),
          ("Open-Source & Teachable", "Heavy C++ server setup required")],
         BORDER_COLOR),
        ("NDMA / Bhuvan / IMD", 
         "Government Portals",
         [("Hazard Avoidance", "Static PDF bulletins & web maps"),
          ("Custom Danger Polygons", "Visual layers only; non-routable"),
          ("Continuous Risk Metric", "Weather alerts (Yellow/Orange/Red)"),
          ("Multi-Hub Fleet Allocation", "Manual district administrative orders"),
          ("Open-Source & Teachable", "Closed internal workflows")],
         BORDER_COLOR),
        ("ReliefRoute India v2 (Ours)", 
         "Dynamic Humanitarian Router",
         [("Hazard Avoidance", "Real-time live multi-hazard feeds"),
          ("Custom Danger Polygons", "Live drawing tool (sf st_intersects)"),
          ("Continuous Risk Metric", "Weighted Risk Index (WRI, lambda 0-10)"),
          ("Multi-Hub Fleet Allocation", "Linear Programming (lpSolve) + VRP"),
          ("Open-Source & Teachable", "100% R/Shiny, reproducible, MIT")],
         PRIMARY_BLUE)
    ]

    for idx, (title, tag, features, border_col) in enumerate(solutions):
        x_pos = Inches(0.8 + idx * 2.95)
        is_ours = (idx == 3)
        bg = RGBColor(240, 253, 250) if is_ours else WHITE
        card = add_card(s3, x_pos, Inches(1.85), Inches(2.8), Inches(5.1), bg, border_col)
        
        # Header banner
        tb = s3.shapes.add_textbox(x_pos + Inches(0.15), Inches(1.95), Inches(2.5), Inches(0.8))
        tf = tb.text_frame
        tf.word_wrap = True
        p_t = tf.paragraphs[0]
        p_t.text = title
        p_t.font.size = Pt(13)
        p_t.font.bold = True
        p_t.font.color.rgb = PRIMARY_BLUE if is_ours else SLATE_900
        
        p_tag = tf.add_paragraph()
        p_tag.text = tag
        p_tag.font.size = Pt(9.5)
        p_tag.font.color.rgb = EMERALD_GREEN if is_ours else SLATE_500
        p_tag.space_after = Pt(10)

        # Feature rows
        feat_box = s3.shapes.add_textbox(x_pos + Inches(0.15), Inches(2.85), Inches(2.5), Inches(3.9))
        tf_f = feat_box.text_frame
        tf_f.word_wrap = True
        tf_f.margin_left = tf_f.margin_top = tf_f.margin_right = tf_f.margin_bottom = 0
        
        for f_idx, (f_name, f_val) in enumerate(features):
            p_fn = tf_f.paragraphs[0] if f_idx == 0 else tf_f.add_paragraph()
            p_fn.text = f_name.upper()
            p_fn.font.size = Pt(8)
            p_fn.font.bold = True
            p_fn.font.color.rgb = SLATE_500
            
            p_fv = tf_f.add_paragraph()
            p_fv.text = ("✔ " if is_ours else "✗ ") + f_val
            p_fv.font.size = Pt(9.5)
            p_fv.font.bold = is_ours
            p_fv.font.color.rgb = (PRIMARY_BLUE if is_ours else SLATE_700)
            p_fv.space_after = Pt(8)

    # =========================================================================
    # SLIDE 4: THE CORE INNOVATION - WEIGHTED RISK INDEX (WRI)
    # =========================================================================
    s4 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s4, LIGHT_BG)
    add_header(s4, "Mathematical Formulation & Innovation", 
               "The Weighted Risk Index (WRI) & Risk-Penalised Cost Function",
               "Treating disaster danger not merely as a binary impassable wall, but as a continuous optimization trade-off.")

    # Left: Mathematical Formula Cards
    left_w = Inches(6.0)
    card_math = add_card(s4, Inches(0.8), Inches(1.85), left_w, Inches(5.1), WHITE, PRIMARY_BLUE)
    
    tb_m = s4.shapes.add_textbox(Inches(1.1), Inches(2.05), Inches(5.4), Inches(4.7))
    tf_m = tb_m.text_frame
    tf_m.word_wrap = True
    
    p_m1 = tf_m.paragraphs[0]
    p_m1.text = "1. The Weighted Risk Index (0 to 100)"
    p_m1.font.size = Pt(14)
    p_m1.font.bold = True
    p_m1.font.color.rgb = SLATE_900
    p_m1.space_after = Pt(6)

    p_eq1 = tf_m.add_paragraph()
    p_eq1.text = "WRI = 100 × ( wH·H + wR·V + wS·S ) / ( wH + wR + wS )"
    p_eq1.font.size = Pt(12)
    p_eq1.font.bold = True
    p_eq1.font.color.rgb = NAVY_BLUE
    p_eq1.space_after = Pt(14)

    p_m2 = tf_m.add_paragraph()
    p_m2.text = "2. Hazard-Induced Travel Slowdown"
    p_m2.font.size = Pt(14)
    p_m2.font.bold = True
    p_m2.font.color.rgb = SLATE_900
    p_m2.space_after = Pt(6)

    p_eq2 = tf_m.add_paragraph()
    p_eq2.text = "Time = Base_Time / ( 1 - 0.45 · H )"
    p_eq2.font.size = Pt(12)
    p_eq2.font.bold = True
    p_eq2.font.color.rgb = NAVY_BLUE
    p_eq2.space_after = Pt(14)

    p_m3 = tf_m.add_paragraph()
    p_m3.text = "3. Risk-Averse Routing Cost Function"
    p_m3.font.size = Pt(14)
    p_m3.font.bold = True
    p_m3.font.color.rgb = SLATE_900
    p_m3.space_after = Pt(6)

    p_eq3 = tf_m.add_paragraph()
    p_eq3.text = "Cost = Time × [ 1 + λ × ( WRI / 100 ) × 2 ]"
    p_eq3.font.size = Pt(12)
    p_eq3.font.bold = True
    p_eq3.font.color.rgb = NAVY_BLUE
    p_eq3.space_after = Pt(14)

    p_m4 = tf_m.add_paragraph()
    p_m4.text = "• λ = 0: Disregards hazards entirely (pure commercial GPS behavior).\n• λ > 0: Convoys make calculated, safe detours around high-risk segments.\n• Hazard ≥ threshold or touching no-go polygon: Edge is pruned immediately."
    p_m4.font.size = Pt(10)
    p_m4.font.color.rgb = SLATE_700

    # Right: 4 Dimension Cards
    dims = [
        ("H : Hazard Exposure", 
         "Calculated dynamically against 3-day rainfall forecast (Open-Meteo), GloFAS flood discharge signals, USGS earthquakes, and NASA EONET events.", 
         ORANGE_ALERT),
        ("V : Road Vulnerability", 
         "Physical corridor resilience: hill-terrain risk factors, seasonal flood plain exposure, and highway structural classifications.", 
         PURPLE_ACC),
        ("S : Security & Access", 
         "Civil constraints, administrative checkpoint delays, and conflict/insurgency vulnerability along transit routes.", 
         PRIMARY_BLUE),
        ("λ : Tunable Risk Aversion (0 to 10)", 
         "Live interactive UI slider allowing commanders to choose between urgency (speed) vs. convoy protection (safety).", 
         EMERALD_GREEN)
    ]

    for idx, (d_title, d_desc, d_col) in enumerate(dims):
        y_pos = Inches(1.85 + idx * 1.3)
        c = add_card(s4, Inches(7.1), y_pos, Inches(5.4), Inches(1.15))
        
        strip = s4.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(7.1), y_pos, Inches(0.1), Inches(1.15))
        strip.fill.solid()
        strip.fill.fore_color.rgb = d_col
        strip.line.fill.background()

        tb = s4.shapes.add_textbox(Inches(7.35), y_pos + Inches(0.08), Inches(5.0), Inches(1.0))
        tf = tb.text_frame
        tf.word_wrap = True
        p1 = tf.paragraphs[0]
        p1.text = d_title
        p1.font.size = Pt(12)
        p1.font.bold = True
        p1.font.color.rgb = SLATE_900
        p1.space_after = Pt(2)

        p2 = tf.add_paragraph()
        p2.text = d_desc
        p2.font.size = Pt(9.5)
        p2.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 5: DUAL OPTIMIZATION ENGINES (LP ALLOCATION + CONVOY VRP)
    # =========================================================================
    s5 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s5, LIGHT_BG)
    add_header(s5, "Operations Research Core", 
               "Dual Optimization: Multi-Hub Allocation & Multi-Stop Convoy VRP",
               "Coupling macro-level inventory distribution with micro-level vehicle tour scheduling.")

    # Engine 1: Transportation LP
    add_card(s5, Inches(0.8), Inches(1.85), Inches(5.7), Inches(5.1), WHITE, BORDER_COLOR)
    tb_e1 = s5.shapes.add_textbox(Inches(1.1), Inches(2.05), Inches(5.1), Inches(4.7))
    tf_e1 = tb_e1.text_frame
    tf_e1.word_wrap = True
    
    p_e1 = tf_e1.paragraphs[0]
    p_e1.text = "ENGINE 1: Multi-Hub Fleet Allocation"
    p_e1.font.size = Pt(15)
    p_e1.font.bold = True
    p_e1.font.color.rgb = PRIMARY_BLUE
    p_e1.space_after = Pt(4)

    p_sub1 = tf_e1.add_paragraph()
    p_sub1.text = "Linear Programming via lpSolve::lp.transport"
    p_sub1.font.size = Pt(11)
    p_sub1.font.bold = True
    p_sub1.font.color.rgb = SLATE_500
    p_sub1.space_after = Pt(14)

    lp_points = [
        ("Global Cost Minimization", "Dispatches relief stocks (tonnes) from multiple supply hubs to disaster camps across India at minimal total risk-weighted rupee cost."),
        ("Dynamic Census Demand", "Camp demands scale dynamically based on Census-2011 population, disaster severity, and ration requirements (kg/person/day)."),
        ("Transparent Shortfall Reporting", "Incorporates a virtual dummy supplier so unreachable or unsupplied demand is explicitly flagged with unmet tonnes, not hidden.")
    ]
    for pt_h, pt_b in lp_points:
        p = tf_e1.add_paragraph()
        p.text = f"• {pt_h}: {pt_b}"
        p.font.size = Pt(10.5)
        p.font.color.rgb = SLATE_700
        p.space_after = Pt(10)

    # Engine 2: Convoy VRP
    add_card(s5, Inches(6.8), Inches(1.85), Inches(5.7), Inches(5.1), WHITE, BORDER_COLOR)
    tb_e2 = s5.shapes.add_textbox(Inches(7.1), Inches(2.05), Inches(5.1), Inches(4.7))
    tf_e2 = tb_e2.text_frame
    tf_e2.word_wrap = True

    p_e2 = tf_e2.paragraphs[0]
    p_e2.text = "ENGINE 2: Multi-Stop Convoy Planner"
    p_e2.font.size = Pt(15)
    p_e2.font.bold = True
    p_e2.font.color.rgb = NAVY_BLUE
    p_e2.space_after = Pt(4)

    p_sub2 = tf_e2.add_paragraph()
    p_sub2.text = "Capacitated Vehicle Routing (Clarke-Wright Savings)"
    p_sub2.font.size = Pt(11)
    p_sub2.font.bold = True
    p_sub2.font.color.rgb = SLATE_500
    p_sub2.space_after = Pt(14)

    vrp_points = [
        ("Multi-Drop Savings Heuristic", "Merges independent out-and-back delivery trips into consolidated multi-stop convoy circuits: Savings(i, j) = Cost(Hub, i) + Cost(Hub, j) - Cost(i, j)."),
        ("Truck Capacity Constraints", "Respects maximum truck payload (default 10 tonnes per convoy lorry), clustering neighboring affected districts safely."),
        ("Fuel & Fleet Efficiency", "Conserves up to 35% in total distance and fuel consumption while ensuring trucks travel in escorted convoys for maximum security.")
    ]
    for pt_h, pt_b in vrp_points:
        p = tf_e2.add_paragraph()
        p.text = f"• {pt_h}: {pt_b}"
        p.font.size = Pt(10.5)
        p.font.color.rgb = SLATE_700
        p.space_after = Pt(10)

    # =========================================================================
    # SLIDE 6: SYSTEM ARCHITECTURE & DATA FLOW
    # =========================================================================
    s6 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s6, LIGHT_BG)
    add_header(s6, "System Architecture & Engineering Pipeline", 
               "End-to-End Pipeline: Ingestion → Spatial Graph Engine → Decision UI",
               "How live public APIs, graph mathematics, and reactive Shiny UI interact seamlessly.")

    arch_steps = [
        ("LAYER 1: DATA INGESTION",
         "Live Public APIs & Datasets",
         ["Open-Meteo: 3-day rain forecast & ERA5 historical reanalysis",
          "USGS: Real-time M4+ earthquakes (14-day window)",
          "NASA EONET: Natural hazard events (floods, fires, storms)",
          "OSM / OSRM: Real highway geometry & truck travel times",
          "Census of India: District population baseline priors"],
         NAVY_BLUE),
        ("LAYER 2: CORE GRAPH ENGINE",
         "Spatial & Operations Research",
         ["Spatial Vectorization (sf): 48 cities & 69 arterial highway corridors",
          "Dynamic Polygon Clipping: Live road closure via sf::st_intersects",
          "WRI Risk Engine: Penalised cost calculation per edge",
          "Dijkstra Shortest Paths: igraph risk-penalised routing",
          "Fleet Solvers: lpSolve Transportation LP + Clarke-Wright VRP"],
         PRIMARY_BLUE),
        ("LAYER 3: INTERACTIVE DASHBOARD",
         "R Shiny & Decision Support",
         ["Leaflet Map: Multi-layer view (routes, hazards, no-go polygons)",
          "Supply/Demand Heatmaps: Population need vs. hub stock",
          "Sensitivity Curves: Plotly lambda risk-tradeoff graphs",
          "Executive SitRep: Auto-generated HTML / PDF printable reports",
          "Bilingual Labels: English and Hindi interface support"],
         EMERALD_GREEN)
    ]

    for idx, (l_tag, l_title, l_items, l_col) in enumerate(arch_steps):
        x_pos = Inches(0.8 + idx * 3.95)
        add_card(s6, x_pos, Inches(1.85), Inches(3.8), Inches(5.1), WHITE, BORDER_COLOR)
        
        # Header banner
        strip = s6.shapes.add_shape(MSO_SHAPE.RECTANGLE, x_pos, Inches(1.85), Inches(3.8), Inches(0.1))
        strip.fill.solid()
        strip.fill.fore_color.rgb = l_col
        strip.line.fill.background()

        tb = s6.shapes.add_textbox(x_pos + Inches(0.2), Inches(2.1), Inches(3.4), Inches(4.6))
        tf = tb.text_frame
        tf.word_wrap = True
        
        p1 = tf.paragraphs[0]
        p1.text = l_tag
        p1.font.size = Pt(10)
        p1.font.bold = True
        p1.font.color.rgb = l_col
        p1.space_after = Pt(2)

        p2 = tf.add_paragraph()
        p2.text = l_title
        p2.font.size = Pt(13)
        p2.font.bold = True
        p2.font.color.rgb = SLATE_900
        p2.space_after = Pt(14)

        for item in l_items:
            pi = tf.add_paragraph()
            pi.text = f"• {item}"
            pi.font.size = Pt(10)
            pi.font.color.rgb = SLATE_700
            pi.space_after = Pt(8)

    # =========================================================================
    # SLIDE 7: TECH STACK BREAKDOWN
    # =========================================================================
    s7 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s7, LIGHT_BG)
    add_header(s7, "Technology Stack & Implementation", 
               "Production-Grade Open Source Ecosystem",
               "Built entirely in R with clean spatial, optimization, and automated CI/CD tooling.")

    tech_categories = [
        ("Framework & UI", "R (>= 4.1), Shiny, shinydashboard", 
         "Modular reactive architecture; responsive side-panels, tabbed routing, value boxes, and mobile-friendly CSS overrides.", 
         PRIMARY_BLUE),
        ("Geospatial & Maps", "sf, leaflet, leaflet.extras", 
         "Simple Features spatial standard in R, Leaflet vector layers, geodesic buffer calculations, and real-time polygon drawing tools.", 
         EMERALD_GREEN),
        ("Operations Research", "igraph, lpSolve, Custom VRP", 
         "Fast C-backed Dijkstra graph algorithm for risk-weighted shortest paths, simplex LP for multi-hub allocation, Clarke-Wright convoy VRP.", 
         NAVY_BLUE),
        ("Public Data APIs", "Open-Meteo, USGS, NASA, OSRM", 
         "Automated REST clients (httr, jsonlite) fetching live rainfall, GloFAS river discharge, seismic telemetry, and OSM road geometry.", 
         AMBER_YELLOW),
        ("Testing & Quality", "testthat, GitHub Actions CI", 
         "Automated unit test suite verifying network connectivity, WRI formula behavior, and LP feasibility; tested on Ubuntu 22.04 LTS runners.", 
         PURPLE_ACC),
        ("Visuals & Reports", "plotly, DT, htmltools", 
         "Interactive sensitivity curves, searchable data tables, and zero-dependency HTML executive situation report generator.", 
         ROSE_RED)
    ]

    for idx, (cat_title, cat_tech, cat_desc, col) in enumerate(tech_categories):
        r = idx // 3
        c = idx % 3
        x_pos = Inches(0.8 + c * 3.95)
        y_pos = Inches(1.85 + r * 2.55)
        
        card = add_card(s7, x_pos, y_pos, Inches(3.8), Inches(2.35), WHITE, BORDER_COLOR)
        
        # Colored top bar
        bar = s7.shapes.add_shape(MSO_SHAPE.RECTANGLE, x_pos, y_pos, Inches(3.8), Inches(0.08))
        bar.fill.solid()
        bar.fill.fore_color.rgb = col
        bar.line.fill.background()

        tb = s7.shapes.add_textbox(x_pos + Inches(0.2), y_pos + Inches(0.18), Inches(3.4), Inches(2.0))
        tf = tb.text_frame
        tf.word_wrap = True
        
        p1 = tf.paragraphs[0]
        p1.text = cat_title.upper()
        p1.font.size = Pt(9.5)
        p1.font.bold = True
        p1.font.color.rgb = col
        p1.space_after = Pt(2)

        p2 = tf.add_paragraph()
        p2.text = cat_tech
        p2.font.size = Pt(12)
        p2.font.bold = True
        p2.font.color.rgb = SLATE_900
        p2.space_after = Pt(6)

        p3 = tf.add_paragraph()
        p3.text = cat_desc
        p3.font.size = Pt(9.5)
        p3.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 8: UNIQUE CAPABILITIES & REAL DISASTER REPLAY
    # =========================================================================
    s8 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s8, LIGHT_BG)
    add_header(s8, "Key Features & Disaster Simulation", 
               "Interactive Capabilities & Historical Disaster Replay",
               "Evaluating real-world performance against India's most destructive historical catastrophes.")

    feats = [
        ("Live Interactive Polygon Exclusion", 
         "Field teams sketching dangerous terrain or flooded sections on the Leaflet map triggers instant road pruning (sf::st_intersects) with zero re-indexing delay.",
         "Interactive Tooling"),
        ("Historical ERA5 Disaster Replay", 
         "Replay exact historical atmospheric rainfall conditions: Kerala 2018 (380+ dead), Chennai 2015, Uttarakhand cloudburst 2013, Cyclone Fani 2019, Assam floods 2024.",
         "Empirical Validation"),
        ("Route Comparison Engine", 
         "Side-by-side diagnostic: GPS Fastest vs. Closure-Aware vs. WRI Optimal. Reports exact road hazard exposure count, travel time trade-off, and rupee budget.",
         "Explainable AI"),
        ("Situation Report Download (SitRep)", 
         "Generates a standalone, timestamped executive HTML SitRep with KPI value cards, truck trip assignments, unmet demand warnings, and printable PDF layout.",
         "Mission Ready")
    ]

    for idx, (f_title, f_desc, f_tag) in enumerate(feats):
        r = idx // 2
        c = idx % 2
        x_pos = Inches(0.8 + c * 5.9)
        y_pos = Inches(1.85 + r * 2.55)
        
        card = add_card(s8, x_pos, y_pos, Inches(5.7), Inches(2.35), WHITE, BORDER_COLOR)
        
        tb = s8.shapes.add_textbox(x_pos + Inches(0.25), y_pos + Inches(0.2), Inches(5.2), Inches(1.95))
        tf = tb.text_frame
        tf.word_wrap = True
        
        p1 = tf.paragraphs[0]
        p1.text = f_tag.upper()
        p1.font.size = Pt(9.5)
        p1.font.bold = True
        p1.font.color.rgb = PRIMARY_BLUE
        p1.space_after = Pt(2)

        p2 = tf.add_paragraph()
        p2.text = f_title
        p2.font.size = Pt(13)
        p2.font.bold = True
        p2.font.color.rgb = SLATE_900
        p2.space_after = Pt(6)

        p3 = tf.add_paragraph()
        p3.text = f_desc
        p3.font.size = Pt(10)
        p3.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 9: HONEST LIMITATIONS (VIVA & EVALUATION READY)
    # =========================================================================
    s9 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s9, LIGHT_BG)
    add_header(s9, "Academic Rigor & Limitations", 
               "Honest Limitations (Essential for Viva & Defense)",
               "Transparently addressing current engineering constraints and domain assumptions.")

    limits = [
        ("1. Highway Corridor vs. Last-Mile Streets", 
         "The current graph contains 48 cities and 69 arterial highway corridors. While real OSM geometry provides accurate curve distances and elevations, it does not route down to remote rural panchayat roads.",
         AMBER_YELLOW),
        ("2. Synthetic Vulnerability & Security Priors", 
         "Hub inventory levels, bridge structural vulnerabilities, and security ratings currently rely on heuristic assumptions and Census distributions rather than live government inventory databases.",
         AMBER_YELLOW),
        ("3. Meteorological Reanalysis Resolution", 
         "ERA5 rainfall is delivered on a 0.25° grid (~25 km resolution). While accurate for regional monsoon patterns, it inherently smooths hyper-local cloudbursts (e.g., flash floods in Himalayan valleys).",
         ROSE_RED),
        ("4. Public API Dependency & Connectivity", 
         "Live mode requires HTTP access to external APIs (Open-Meteo, USGS, NASA). While simulated disaster presets function 100% offline, field teams in communication blackouts need mesh caching.",
         ROSE_RED)
    ]

    for idx, (l_title, l_desc, l_col) in enumerate(limits):
        r = idx // 2
        c = idx % 2
        x_pos = Inches(0.8 + c * 5.9)
        y_pos = Inches(1.85 + r * 2.55)
        
        card = add_card(s9, x_pos, y_pos, Inches(5.7), Inches(2.35), WHITE, BORDER_COLOR)
        
        strip = s9.shapes.add_shape(MSO_SHAPE.RECTANGLE, x_pos, y_pos, Inches(0.1), Inches(2.35))
        strip.fill.solid()
        strip.fill.fore_color.rgb = l_col
        strip.line.fill.background()

        tb = s9.shapes.add_textbox(x_pos + Inches(0.25), y_pos + Inches(0.2), Inches(5.2), Inches(1.95))
        tf = tb.text_frame
        tf.word_wrap = True
        
        p1 = tf.paragraphs[0]
        p1.text = l_title
        p1.font.size = Pt(13)
        p1.font.bold = True
        p1.font.color.rgb = SLATE_900
        p1.space_after = Pt(8)

        p2 = tf.add_paragraph()
        p2.text = l_desc
        p2.font.size = Pt(10.5)
        p2.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 10: FUTURE WORKS & PRACTICAL ROADMAP
    # =========================================================================
    s10 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s10, LIGHT_BG)
    add_header(s10, "Future Scope & Project Evolution", 
               "Future Works: From Educational Prototype to National Deployment",
               "Roadmap for transforming ReliefRoute India into a field-deployed institutional platform.")

    # Left: 4 Roadmap Phases
    phases = [
        ("Phase 1: National Telemetry Integration", "Direct API integration with India-WRIS / Central Water Commission (CWC) river gauges, and IMD Doppler Weather Radar district warnings."),
        ("Phase 2: Offline-First Field Driver App", "Lightweight offline mobile client for convoy drivers with satellite telemetry / LoRa mesh networking across internet blackout zones."),
        ("Phase 3: Drone Reconnaissance Ingestion", "Automated computer vision pipelines to ingest post-disaster drone imagery and detect washed-out bridges and landslides in near real-time."),
        ("Phase 4: Multi-Commodity Cargo Routing", "Differentiating fleet capacities between refrigerated medical cold-chains, potable water tankers, and dry ration trucks with priority deadlines.")
    ]

    for idx, (p_title, p_desc) in enumerate(phases):
        y_pos = Inches(1.85 + idx * 1.3)
        card = add_card(s10, Inches(0.8), y_pos, Inches(6.8), Inches(1.15))
        
        strip = s10.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), y_pos, Inches(0.1), Inches(1.15))
        strip.fill.solid()
        strip.fill.fore_color.rgb = EMERALD_GREEN
        strip.line.fill.background()

        tb = s10.shapes.add_textbox(Inches(1.05), y_pos + Inches(0.1), Inches(6.4), Inches(0.95))
        tf = tb.text_frame
        tf.word_wrap = True
        p1 = tf.paragraphs[0]
        p1.text = p_title
        p1.font.size = Pt(12)
        p1.font.bold = True
        p1.font.color.rgb = SLATE_900
        p1.space_after = Pt(2)

        p2 = tf.add_paragraph()
        p2.text = p_desc
        p2.font.size = Pt(9.5)
        p2.font.color.rgb = SLATE_700

    # Right: Photo of Safe Convoy
    if os.path.exists(img_convoy):
        card_pic2 = add_card(s10, Inches(7.8), Inches(1.85), Inches(4.7), Inches(5.1))
        s10.shapes.add_picture(img_convoy, Inches(7.9), Inches(1.95), Inches(4.5), Inches(3.7))
        tb_c2 = s10.shapes.add_textbox(Inches(7.9), Inches(5.75), Inches(4.5), Inches(1.0))
        tf_c2 = tb_c2.text_frame
        tf_c2.word_wrap = True
        p_c2 = tf_c2.paragraphs[0]
        p_c2.text = "Target Deployment: Coordinated, escorted relief convoys successfully navigating clear bypass routes to deliver lifesaving aid on schedule."
        p_c2.font.size = Pt(10)
        p_c2.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 11: CONCLUSION & REPO DETAILS (Dark Mode)
    # =========================================================================
    s11 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s11, DARK_BG)

    tb_end = s11.shapes.add_textbox(Inches(1.2), Inches(1.0), Inches(10.9), Inches(5.5))
    tf_end = tb_end.text_frame
    tf_end.word_wrap = True

    p_eb = tf_end.paragraphs[0]
    p_eb.text = "CONCLUSION & PROJECT SUMMARY"
    p_eb.font.size = Pt(12)
    p_eb.font.bold = True
    p_eb.font.color.rgb = EMERALD_GREEN
    p_eb.space_after = Pt(10)

    p_et = tf_end.add_paragraph()
    p_et.text = "ReliefRoute India v2: Key Takeaways"
    p_et.font.size = Pt(32)
    p_et.font.bold = True
    p_et.font.color.rgb = WHITE
    p_et.space_after = Pt(20)

    concl_points = [
        "1. Bridges the Gap: Connects static weather bulletins (IMD/NDMA) directly with operational fleet routing.",
        "2. Proven Risk Trade-Off: Weighted Risk Index (WRI) prevents convoys from entering deadly flood zones with modest travel-time overhead.",
        "3. Joint Macro-Micro Optimization: Balances multi-hub stock allocation (LP) with multi-stop vehicle tours (Clarke-Wright VRP).",
        "4. Production Quality & Reproducibility: Clean modular architecture, unit tests, automated CI/CD, and open MIT license."
    ]
    for pt in concl_points:
        p = tf_end.add_paragraph()
        p.text = pt
        p.font.size = Pt(14)
        p.font.color.rgb = RGBColor(226, 232, 240)
        p.space_after = Pt(12)

    p_space = tf_end.add_paragraph()
    p_space.text = " "
    p_space.space_after = Pt(14)

    p_link = tf_end.add_paragraph()
    p_link.text = "GitHub Repository: https://github.com/nisargad1/ReliefRoute-India\nAuthor: Nisarga Devaraj  •  License: MIT  •  Built with R & Shiny"
    p_link.font.size = Pt(12)
    p_link.font.bold = True
    p_link.font.color.rgb = PRIMARY_BLUE

    # Save to both repo docs and user's Downloads folder
    output_path1 = r"C:\Users\Nisarga\Downloads\ReliefRoute-India-v2\ReliefRoute-India\docs\ReliefRoute_India_Presentation.pptx"
    output_path2 = r"C:\Users\Nisarga\Downloads\ReliefRoute_India_Presentation.pptx"
    
    prs.save(output_path1)
    prs.save(output_path2)
    print(f"Presentation successfully saved to:\n  1. {output_path1}\n  2. {output_path2}")

if __name__ == "__main__":
    create_presentation()
