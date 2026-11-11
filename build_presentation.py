import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def create_presentation():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_slide_layout = prs.slide_layouts[6]

    # Clean, Modern Color Palette
    DARK_BG = RGBColor(11, 25, 44)        # Deep Navy
    DARK_CARD = RGBColor(21, 44, 76)      # Slate Navy Card
    LIGHT_BG = RGBColor(248, 250, 252)    # Clean Light Background (Slate 50)
    WHITE = RGBColor(255, 255, 255)
    SLATE_900 = RGBColor(15, 23, 42)      # Deep Charcoal Text
    SLATE_700 = RGBColor(51, 65, 85)      # Body Text
    SLATE_500 = RGBColor(100, 116, 139)   # Subtitles / Muted
    BORDER_COLOR = RGBColor(226, 232, 240) # Subtle Card Border
    
    PRIMARY_BLUE = RGBColor(14, 116, 144)  # Teal Blue
    NAVY_BLUE = RGBColor(30, 58, 138)     # Deep Royal Blue
    ORANGE_ALERT = RGBColor(234, 88, 12)  # Warning Orange
    EMERALD_GREEN = RGBColor(16, 185, 129)# Safe Emerald
    ROSE_RED = RGBColor(225, 29, 72)      # Alert Red
    AMBER_YELLOW = RGBColor(217, 119, 6)  # Warning Amber
    PURPLE_ACC = RGBColor(126, 34, 206)   # Purple

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
    p_badge.text = "ACADEMIC MINI PROJECT  •  DISASTER RELIEF LOGISTICS"
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
    p_sub.text = "Smart & Safe Truck Routing\nDuring Disasters in India"
    p_sub.font.size = Pt(20)
    p_sub.font.color.rgb = RGBColor(186, 215, 233)
    p_sub.space_after = Pt(24)

    p_desc = tf1.add_paragraph()
    p_desc.text = "An easy-to-use map dashboard that guides emergency relief trucks safely around flooded roads, landslides, and storm zones across India."
    p_desc.font.size = Pt(13)
    p_desc.font.color.rgb = RGBColor(148, 163, 184)
    p_desc.space_after = Pt(28)

    p_meta = tf1.add_paragraph()
    p_meta.text = "Created by: Nisarga Devaraj (github.com/nisargad1)\nBuilt with: R, Shiny, Leaflet & OpenStreetMap\nNovember 2026  •  Free & Open Source (MIT License)"
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
        p_cap.text = "Smart Navigation in Action: Helping emergency supply trucks steer clear of flooded roads and mountain landslides during heavy monsoon storms."
        p_cap.font.size = Pt(10)
        p_cap.font.color.rgb = RGBColor(148, 163, 184)

    # =========================================================================
    # SLIDE 2: THE PROBLEM STATEMENT
    # =========================================================================
    s2 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s2, LIGHT_BG)
    add_header(s2, "The Real-World Problem", 
               "Why Regular GPS Apps Fail During Emergencies",
               "Everyday navigation apps like Google Maps are made for normal traffic, not disaster zones.")

    cards_data = [
        ("1. Fastest Route is Not Always Safe", 
         "Normal map apps always pick the shortest or quickest road. But during heavy floods (like in Kerala or Assam), that 'fastest' highway is often washed out or underwater, leaving trucks trapped.",
         ROSE_RED),
        ("2. Warning Updates Are Scattered & Slow", 
         "Government weather and flood warnings usually come as news updates, PDF circulars, or radio bulletins. Drivers and managers cannot easily plug these alerts into a map to see safe routes.",
         AMBER_YELLOW),
        ("3. Huge Costs and High Stakes", 
         "Up to 80% of all disaster spending goes into transporting goods. When trucks take wrong, blocked roads, relief items get ruined and help arrives too late for people in need.",
         NAVY_BLUE)
    ]

    for idx, (head, body, acc_col) in enumerate(cards_data):
        y_pos = Inches(1.85 + idx * 1.65)
        card = add_card(s2, Inches(0.8), y_pos, Inches(6.8), Inches(1.48))
        
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
        p2.font.size = Pt(11)
        p2.font.color.rgb = SLATE_700

    # Right Column: Visual Photo & Stat Callout
    if os.path.exists(img_flood):
        card_pic = add_card(s2, Inches(7.8), Inches(1.85), Inches(4.7), Inches(3.3))
        s2.shapes.add_picture(img_flood, Inches(7.9), Inches(1.95), Inches(4.5), Inches(2.7))
        cap_b = s2.shapes.add_textbox(Inches(7.9), Inches(4.7), Inches(4.5), Inches(0.4))
        p_c = cap_b.text_frame.paragraphs[0]
        p_c.text = "Real Challenge: Blocked and flooded highway during Indian monsoons."
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
    p_st2.text = "Of all disaster relief funding is spent on transportation and fuel. When roads are blocked, essential food, water, and medicines get delayed."
    p_st2.font.size = Pt(10.5)
    p_st2.font.color.rgb = SLATE_900

    # =========================================================================
    # SLIDE 3: EXISTING SOLUTIONS VS OUR SOLUTION
    # =========================================================================
    s3 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s3, LIGHT_BG)
    add_header(s3, "Comparison with Existing Tools", 
               "What Exists Today vs. ReliefRoute India",
               "How our solution solves the key missing pieces in current apps.")

    solutions = [
        ("Regular Map Apps\n(Google Maps)", 
         "City Driving",
         [("Avoids Disasters?", "No (only traffic jams and tolls)"),
          ("Custom Danger Zones?", "Cannot draw flood zones"),
          ("Safety Risk Score?", "Only checks travel time/distance"),
          ("Warehouse Balancing?", "Only 1 car/trip at a time"),
          ("Access & Price", "Proprietary, commercial service")],
         BORDER_COLOR),
        ("Open-Source Routers\n(OSRM / ORS)", 
         "Standard Routing",
         [("Avoids Disasters?", "Basic roadblocks only"),
          ("Custom Danger Zones?", "Slow and clunky to update"),
          ("Safety Risk Score?", "Limited risk adjustments"),
          ("Warehouse Balancing?", "Cannot plan supply sharing"),
          ("Access & Price", "Complex server configuration")],
         BORDER_COLOR),
        ("Government Sites\n(NDMA / IMD)", 
         "Weather Alerts",
         [("Avoids Disasters?", "Shows warnings on static web maps"),
          ("Custom Danger Zones?", "Informational only, not for GPS"),
          ("Safety Risk Score?", "Color codes (Yellow/Orange/Red)"),
          ("Warehouse Balancing?", "Managed manually by phone calls"),
          ("Access & Price", "Government internal systems")],
         BORDER_COLOR),
        ("ReliefRoute India\n(Our Solution)", 
         "Disaster Relief",
         [("Avoids Disasters?", "Live rain, flood, and quake feeds"),
          ("Custom Danger Zones?", "1-Click tool to draw no-go zones"),
          ("Safety Risk Score?", "Smart Risk Index with safety slider"),
          ("Warehouse Balancing?", "Automatically balances stocks & camps"),
          ("Access & Price", "100% Free, open-source R code")],
         PRIMARY_BLUE)
    ]

    for idx, (title, tag, features, border_col) in enumerate(solutions):
        x_pos = Inches(0.8 + idx * 2.95)
        is_ours = (idx == 3)
        bg = RGBColor(240, 253, 250) if is_ours else WHITE
        card = add_card(s3, x_pos, Inches(1.85), Inches(2.8), Inches(5.1), bg, border_col)
        
        tb = s3.shapes.add_textbox(x_pos + Inches(0.15), Inches(1.95), Inches(2.5), Inches(0.8))
        tf = tb.text_frame
        tf.word_wrap = True
        p_t = tf.paragraphs[0]
        p_t.text = title
        p_t.font.size = Pt(12.5)
        p_t.font.bold = True
        p_t.font.color.rgb = PRIMARY_BLUE if is_ours else SLATE_900
        
        p_tag = tf.add_paragraph()
        p_tag.text = tag
        p_tag.font.size = Pt(9.5)
        p_tag.font.color.rgb = EMERALD_GREEN if is_ours else SLATE_500
        p_tag.space_after = Pt(10)

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
    add_header(s4, "Our Solution & Method", 
               "How We Calculate Safe Routes: The Risk Index",
               "We give every road a Risk Score so trucks can safely detour around danger.")

    # Left: Simple Math Explanation
    left_w = Inches(6.0)
    card_math = add_card(s4, Inches(0.8), Inches(1.85), left_w, Inches(5.1), WHITE, PRIMARY_BLUE)
    
    tb_m = s4.shapes.add_textbox(Inches(1.1), Inches(2.05), Inches(5.4), Inches(4.7))
    tf_m = tb_m.text_frame
    tf_m.word_wrap = True
    
    p_m1 = tf_m.paragraphs[0]
    p_m1.text = "1. Road Risk Score (From 0 to 100)"
    p_m1.font.size = Pt(14)
    p_m1.font.bold = True
    p_m1.font.color.rgb = SLATE_900
    p_m1.space_after = Pt(4)

    p_eq1 = tf_m.add_paragraph()
    p_eq1.text = "Risk Score = Combining (Weather + Weak Roads + Road Security)"
    p_eq1.font.size = Pt(11.5)
    p_eq1.font.bold = True
    p_eq1.font.color.rgb = NAVY_BLUE
    p_eq1.space_after = Pt(14)

    p_m2 = tf_m.add_paragraph()
    p_m2.text = "2. Weather Delays"
    p_m2.font.size = Pt(14)
    p_m2.font.bold = True
    p_m2.font.color.rgb = SLATE_900
    p_m2.space_after = Pt(4)

    p_eq2 = tf_m.add_paragraph()
    p_eq2.text = "Real Travel Time = Normal Time + Rain / Flood Slowdown"
    p_eq2.font.size = Pt(11.5)
    p_eq2.font.bold = True
    p_eq2.font.color.rgb = NAVY_BLUE
    p_eq2.space_after = Pt(14)

    p_m3 = tf_m.add_paragraph()
    p_m3.text = "3. Picking the Best Route"
    p_m3.font.size = Pt(14)
    p_m3.font.bold = True
    p_m3.font.color.rgb = SLATE_900
    p_m3.space_after = Pt(4)

    p_eq3 = tf_m.add_paragraph()
    p_eq3.text = "Routing Cost = Travel Time + Extra Penalty for High Risk"
    p_eq3.font.size = Pt(11.5)
    p_eq3.font.bold = True
    p_eq3.font.color.rgb = NAVY_BLUE
    p_eq3.space_after = Pt(14)

    p_m4 = tf_m.add_paragraph()
    p_m4.text = "• Slider at Zero: Behaves like normal GPS (fastest route).\n• Slider Higher: Carefully routes trucks around floods and landslides.\n• Dangerous Roads: Roads underwater or inside drawn danger zones are shut down immediately."
    p_m4.font.size = Pt(10)
    p_m4.font.color.rgb = SLATE_700

    # Right: 4 Simple Factors
    dims = [
        ("Weather Danger (H)", 
         "Pulls live rainfall forecasts, river flood alerts, and earthquake reports automatically from weather sensors.", 
         ORANGE_ALERT),
        ("Weak Roads (V)", 
         "Accounts for fragile roads, steep mountain passes, and flood plains that easily crack or submerge.", 
         PURPLE_ACC),
        ("Road Security (S)", 
         "Considers checkpoints, broken bridges, or difficult areas where trucks might get stuck or delayed.", 
         PRIMARY_BLUE),
        ("Safety Slider (λ from 0 to 10)", 
         "A simple slider in the dashboard that lets emergency managers choose between Maximum Speed or Maximum Safety.", 
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
    add_header(s5, "Smart Logistics Features", 
               "Two Smart Tools: Sharing Supplies & Grouping Trucks",
               "Deciding who gets what supplies, and how trucks travel together safely.")

    # Engine 1: Transportation LP
    add_card(s5, Inches(0.8), Inches(1.85), Inches(5.7), Inches(5.1), WHITE, BORDER_COLOR)
    tb_e1 = s5.shapes.add_textbox(Inches(1.1), Inches(2.05), Inches(5.1), Inches(4.7))
    tf_e1 = tb_e1.text_frame
    tf_e1.word_wrap = True
    
    p_e1 = tf_e1.paragraphs[0]
    p_e1.text = "TOOL 1: Fair Supply Sharing"
    p_e1.font.size = Pt(15)
    p_e1.font.bold = True
    p_e1.font.color.rgb = PRIMARY_BLUE
    p_e1.space_after = Pt(4)

    p_sub1 = tf_e1.add_paragraph()
    p_sub1.text = "Which warehouse sends food to which relief camp?"
    p_sub1.font.size = Pt(11)
    p_sub1.font.bold = True
    p_sub1.font.color.rgb = SLATE_500
    p_sub1.space_after = Pt(14)

    lp_points = [
        ("Lowest Overall Cost", "Automatically matches multiple warehouses with relief camps across India at the lowest delivery cost and risk."),
        ("Based on Real Population", "Camps with more people or heavier disaster damage automatically get more supplies."),
        ("Clear Shortage Warnings", "If total food or trucks are not enough, the app clearly shows exactly how many tonnes are still missing.")
    ]
    for pt_h, pt_b in lp_points:
        p = tf_e1.add_paragraph()
        p.text = f"• {pt_h}: {pt_b}"
        p.font.size = Pt(11)
        p.font.color.rgb = SLATE_700
        p.space_after = Pt(12)

    # Engine 2: Convoy VRP
    add_card(s5, Inches(6.8), Inches(1.85), Inches(5.7), Inches(5.1), WHITE, BORDER_COLOR)
    tb_e2 = s5.shapes.add_textbox(Inches(7.1), Inches(2.05), Inches(5.1), Inches(4.7))
    tf_e2 = tb_e2.text_frame
    tf_e2.word_wrap = True

    p_e2 = tf_e2.paragraphs[0]
    p_e2.text = "TOOL 2: Multi-Stop Truck Convoys"
    p_e2.font.size = Pt(15)
    p_e2.font.bold = True
    p_e2.font.color.rgb = NAVY_BLUE
    p_e2.space_after = Pt(4)

    p_sub2 = tf_e2.add_paragraph()
    p_sub2.text = "Grouping trucks into safe, shared journeys"
    p_sub2.font.size = Pt(11)
    p_sub2.font.bold = True
    p_sub2.font.color.rgb = SLATE_500
    p_sub2.space_after = Pt(14)

    vrp_points = [
        ("Multi-Stop Deliveries", "Instead of sending separate trucks back and forth to each village, it creates one round-trip route that delivers to several camps in a row."),
        ("Packed to Capacity", "Ensures every 10-tonne relief truck is fully loaded before leaving, avoiding wasted trips."),
        ("Saves Fuel & Keeps Drivers Safe", "Saves up to 35% in total driving distance and fuel, while keeping trucks traveling together in safe groups.")
    ]
    for pt_h, pt_b in vrp_points:
        p = tf_e2.add_paragraph()
        p.text = f"• {pt_h}: {pt_b}"
        p.font.size = Pt(11)
        p.font.color.rgb = SLATE_700
        p.space_after = Pt(12)

    # =========================================================================
    # SLIDE 6: SYSTEM ARCHITECTURE & DATA FLOW
    # =========================================================================
    s6 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s6, LIGHT_BG)
    add_header(s6, "How the System Works", 
               "System Architecture in 3 Simple Steps",
               "From live public data to smart map directions for relief teams.")

    arch_steps = [
        ("STEP 1: LIVE DATA FEEDS",
         "Pulls Free Public Data",
         ["Open-Meteo: Live 3-day rainfall forecasts & flood signals",
          "USGS: Real-time earthquake alerts",
          "NASA: Natural hazard events (floods, storms, fires)",
          "OpenStreetMap: Real road distances and driving times",
          "Census of India: Population numbers for every district"],
         NAVY_BLUE),
        ("STEP 2: THE ROUTING BRAIN",
         "Calculates Safe Paths",
         ["Connects 48 major Indian cities across 69 main highways",
          "Checks which roads fall inside drawn flood danger zones",
          "Calculates the Risk Score for every highway segment",
          "Finds the best detour around storms using shortest-path math",
          "Solves supply matching so every camp gets fair rations"],
         PRIMARY_BLUE),
        ("STEP 3: EASY DASHBOARD",
         "Interactive Web App",
         ["Color-coded map showing safe routes, warnings, and trucks",
          "Heatmaps showing where relief supplies are needed most",
          "Simple slider to choose speed vs. extra safety",
          "1-Click download of printable summary reports (HTML/PDF)",
          "Bilingual labels in both English and Hindi for field teams"],
         EMERALD_GREEN)
    ]

    for idx, (l_tag, l_title, l_items, l_col) in enumerate(arch_steps):
        x_pos = Inches(0.8 + idx * 3.95)
        add_card(s6, x_pos, Inches(1.85), Inches(3.8), Inches(5.1), WHITE, BORDER_COLOR)
        
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
            pi.font.size = Pt(10.5)
            pi.font.color.rgb = SLATE_700
            pi.space_after = Pt(9)

    # =========================================================================
    # SLIDE 7: TECH STACK BREAKDOWN
    # =========================================================================
    s7 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s7, LIGHT_BG)
    add_header(s7, "Technologies Used", 
               "Simple Tech Stack Overview",
               "Built using standard, reliable, and completely free open-source tools.")

    tech_categories = [
        ("Dashboard & App", "R & Shiny Dashboard", 
         "Builds the interactive web interface with buttons, map layers, tabs, and real-time screen updates.", 
         PRIMARY_BLUE),
        ("Maps & Geography", "Leaflet & sf Package", 
         "Draws interactive maps of India, road polylines, flood circles, and lets users draw shapes on the map.", 
         EMERALD_GREEN),
        ("Routing Math", "igraph & lpSolve", 
         "Crunches the numbers to find the safest routes and solves warehouse supply sharing in seconds.", 
         NAVY_BLUE),
        ("Live Internet Feeds", "Weather & Satellite APIs", 
         "Pulls live weather and earthquake information automatically from Open-Meteo, USGS, NASA, and OSM.", 
         AMBER_YELLOW),
        ("Testing & Quality", "testthat & GitHub Actions", 
         "Automatically runs test checks on every update to guarantee the routes and math are 100% correct.", 
         PURPLE_ACC),
        ("Reports & Charts", "Plotly & HTML Export", 
         "Shows risk trade-off graphs and generates clear summary reports ready to print or save as PDF.", 
         ROSE_RED)
    ]

    for idx, (cat_title, cat_tech, cat_desc, col) in enumerate(tech_categories):
        r = idx // 3
        c = idx % 3
        x_pos = Inches(0.8 + c * 3.95)
        y_pos = Inches(1.85 + r * 2.55)
        
        card = add_card(s7, x_pos, y_pos, Inches(3.8), Inches(2.35), WHITE, BORDER_COLOR)
        
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
        p3.font.size = Pt(10)
        p3.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 8: UNIQUE CAPABILITIES & REAL DISASTER REPLAY
    # =========================================================================
    s8 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s8, LIGHT_BG)
    add_header(s8, "Key Project Features", 
               "Helpful Features Built for Relief Teams",
               "Practical tools designed for both live emergency responses and training drills.")

    feats = [
        ("Draw Danger Zones on the Map", 
         "Emergency workers can simply draw a box or circle over flooded areas on the map. The app immediately closes those roads and finds a safe detour in seconds.",
         "EASY 1-CLICK TOOL"),
        ("Replay Past Indian Disasters", 
         "Test the system against real historical storms: Kerala Floods (2018), Chennai Floods (2015), Uttarakhand Landslides (2013), Cyclone Fani (2019), and Assam (2024).",
         "TESTED WITH REAL DATA"),
        ("Compare Routes Side-by-Side", 
         "View 3 choices at once: (1) Normal GPS path, (2) Avoid Roadblocks path, and (3) Our Safe Route. Clearly see the small extra travel time needed to stay safe.",
         "TRANSPARENT CHOICES"),
        ("Printable Situation Report (SitRep)", 
         "Download a clean summary sheet with total food delivered, truck trip schedules, and any unmet camp needs — ready to print or save as a PDF for commanders.",
         "READY FOR MEETINGS")
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
        p3.font.size = Pt(10.5)
        p3.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 9: HONEST LIMITATIONS (VIVA & EVALUATION READY)
    # =========================================================================
    s9 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s9, LIGHT_BG)
    add_header(s9, "Honest Self-Evaluation", 
               "Current Limitations of the Project",
               "Honest points to mention during viva, defense, or project presentations.")

    limits = [
        ("1. Highway Corridors Only (Not Village Streets)", 
         "The app currently maps 48 major Indian cities and 69 highway routes. It does not yet cover every small village street or unpaved rural mud road.",
         AMBER_YELLOW),
        ("2. Estimated Warehouse Stock & Bridge Data", 
         "Warehouse stock levels, bridge strength scores, and security ratings currently use estimated figures. Real government use will require live warehouse database connections.",
         AMBER_YELLOW),
        ("3. Weather Block Size (25 km Grid)", 
         "Satellite rain data comes in 25-kilometer blocks. While great for regional monsoon storms, it can smooth out sudden, tiny flash floods in narrow mountain valleys.",
         ROSE_RED),
        ("4. Internet Needed for Live Updates", 
         "Pulling live weather and earthquake data needs internet access. Saved historical scenarios work completely offline, but real-time mode needs a data connection.",
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
        p2.font.size = Pt(11)
        p2.font.color.rgb = SLATE_700

    # =========================================================================
    # SLIDE 10: FUTURE WORKS & PRACTICAL ROADMAP
    # =========================================================================
    s10 = prs.slides.add_slide(blank_slide_layout)
    add_bg(s10, LIGHT_BG)
    add_header(s10, "Future Improvements", 
               "What We Plan to Build Next",
               "Roadmap to turn this student project into a field-ready emergency platform.")

    phases = [
        ("1. Connect to Live River Flood Sensors", "Link directly with Central Water Commission (CWC) river gauges and IMD radar for early flash flood warnings."),
        ("2. Offline Phone App for Truck Drivers", "Build a lightweight driver app that works even when phone networks are down, using satellite or walkie-talkie mesh."),
        ("3. Drone Photos to Spot Road Damage", "Use quick drone photos after a flood or landslide to automatically detect broken bridges and update the map instantly."),
        ("4. Separate Relief Supplies by Urgency", "Separate trucks for cold-chain medicines, clean drinking water, and dry food so life-saving medicines get priority.")
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
        p2.font.size = Pt(10)
        p2.font.color.rgb = SLATE_700

    if os.path.exists(img_convoy):
        card_pic2 = add_card(s10, Inches(7.8), Inches(1.85), Inches(4.7), Inches(5.1))
        s10.shapes.add_picture(img_convoy, Inches(7.9), Inches(1.95), Inches(4.5), Inches(3.7))
        tb_c2 = s10.shapes.add_textbox(Inches(7.9), Inches(5.75), Inches(4.5), Inches(1.0))
        tf_c2 = tb_c2.text_frame
        tf_c2.word_wrap = True
        p_c2 = tf_c2.paragraphs[0]
        p_c2.text = "Ultimate Goal: Relief trucks traveling together safely on clear roads, delivering urgent supplies without getting delayed by floods."
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
    p_eb.text = "SUMMARY & CONCLUSION"
    p_eb.font.size = Pt(12)
    p_eb.font.bold = True
    p_eb.font.color.rgb = EMERALD_GREEN
    p_eb.space_after = Pt(10)

    p_et = tf_end.add_paragraph()
    p_et.text = "ReliefRoute India: Key Takeaways"
    p_et.font.size = Pt(32)
    p_et.font.bold = True
    p_et.font.color.rgb = WHITE
    p_et.space_after = Pt(22)

    concl_points = [
        "1. Solves a Real Problem: Regular GPS leads trucks into floods. Our tool routes around shifting danger zones.",
        "2. Balances Speed & Safety: Lets emergency teams decide how much extra time they are willing to take to stay 100% safe.",
        "3. Fair Supply Sharing: Automatically coordinates warehouse stocks so no relief camp is left empty-handed.",
        "4. Saves Money & Fuel: Groups trucks into shared convoys, cutting fuel costs by up to 35%.",
        "5. Free & Tested: Fully working dashboard, tested code, and open source under the MIT License."
    ]
    for pt in concl_points:
        p = tf_end.add_paragraph()
        p.text = pt
        p.font.size = Pt(14)
        p.font.color.rgb = RGBColor(226, 232, 240)
        p.space_after = Pt(12)

    p_space = tf_end.add_paragraph()
    p_space.text = " "
    p_space.space_after = Pt(10)

    p_link = tf_end.add_paragraph()
    p_link.text = "GitHub Repository: https://github.com/nisargad1/ReliefRoute-India\nCreated by: Nisarga Devaraj  •  Built with R & Shiny  •  Thank You!"
    p_link.font.size = Pt(12)
    p_link.font.bold = True
    p_link.font.color.rgb = PRIMARY_BLUE

    # Save to both repo docs and user's Downloads folder
    output_path1 = r"C:\Users\Nisarga\Downloads\ReliefRoute-India-v2\ReliefRoute-India\docs\ReliefRoute_India_Presentation.pptx"
    output_path2 = r"C:\Users\Nisarga\Downloads\ReliefRoute_India_Presentation.pptx"
    
    prs.save(output_path1)
    prs.save(output_path2)
    print(f"Presentation successfully updated with simple English:\n  1. {output_path1}\n  2. {output_path2}")

if __name__ == "__main__":
    create_presentation()
