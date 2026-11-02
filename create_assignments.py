from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import Table, TableStyle, Paragraph, Frame, PageTemplate, BaseDocTemplate, PageBreak, Spacer, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.lib.utils import ImageReader
from PIL import Image
import os

OUT = os.path.join(os.path.dirname(__file__), 'output', 'pdf')
os.makedirs(OUT, exist_ok=True)
W, H = letter
GREEN = colors.HexColor('#526832')
INK = colors.HexColor('#111111')
LIGHT = colors.HexColor('#F2F2F2')
STUDENTS = [
    ('Muhammad Shaheer Ali', '22518', 'SB'),
    ('Zainab bint e shah', '22564', 'CB'),
    ('Muhammad usman Ali', '22620', 'CB'),
    ('Mohiuddin siddique', '22278', 'CB'),
]

S = getSampleStyleSheet()
S.add(ParagraphStyle(name='bodyx', parent=S['BodyText'], fontName='Helvetica', fontSize=8.3, leading=10.5, textColor=INK, spaceAfter=5))
S.add(ParagraphStyle(name='smallx', parent=S['BodyText'], fontName='Helvetica', fontSize=7.4, leading=9, textColor=INK, spaceAfter=3))
S.add(ParagraphStyle(name='bulletx', parent=S['BodyText'], fontName='Helvetica', fontSize=8.1, leading=10, leftIndent=11, firstLineIndent=-7, spaceAfter=3))
S.add(ParagraphStyle(name='h1x', parent=S['Heading2'], fontName='Helvetica-Bold', fontSize=12, leading=14, spaceBefore=2, spaceAfter=7, textColor=INK))
S.add(ParagraphStyle(name='h2x', parent=S['Heading3'], fontName='Helvetica-Bold', fontSize=9.2, leading=11, spaceBefore=5, spaceAfter=4, textColor=INK))
S.add(ParagraphStyle(name='codebox', parent=S['Code'], fontName='Courier', fontSize=8.2, leading=11, leftIndent=18, spaceBefore=4, spaceAfter=8))
S.add(ParagraphStyle(name='cell', parent=S['BodyText'], fontName='Helvetica', fontSize=6.7, leading=8, alignment=TA_CENTER, spaceAfter=0))
S.add(ParagraphStyle(name='cellb', parent=S['BodyText'], fontName='Helvetica-Bold', fontSize=6.7, leading=8, alignment=TA_CENTER, spaceAfter=0))

def P(txt, style='bodyx'):
    return Paragraph(txt, S[style])

def table(data, widths, font=6.7, repeat=1):
    t = Table(data, colWidths=widths, repeatRows=repeat, hAlign='LEFT')
    t.setStyle(TableStyle([
        ('GRID',(0,0),(-1,-1),0.65,colors.black),
        ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E8E8E8')),
        ('VALIGN',(0,0),(-1,-1),'MIDDLE'),
        ('LEFTPADDING',(0,0),(-1,-1),3),('RIGHTPADDING',(0,0),(-1,-1),3),
        ('TOPPADDING',(0,0),(-1,-1),4),('BOTTOMPADDING',(0,0),(-1,-1),4),
    ]))
    return t

def cell(txt, bold=False): return P(str(txt), 'cellb' if bold else 'cell')

# Extract the exact university seal from the first page of the supplied reference PDF.
logo_path = os.path.join(os.path.dirname(__file__), 'tmp', 'abasyn_seal.png')
os.makedirs(os.path.dirname(logo_path), exist_ok=True)
try:
    from pypdf import PdfReader
    reader = PdfReader(r'C:\Users\Shaheer\Downloads\ST-Assign-5-22620.pdf')
    for img in reader.pages[0].images:
        if img.image.width >= 100 and img.image.height >= 100:
            img.image.save(logo_path)
            break
except Exception:
    pass

def cover(c, student):
    name, roll, section = student
    # Exact visual structure of the reference cover page.
    x0, y0, bw, bh = 38, 656, W-76, 126
    c.setFillColor(LIGHT); c.rect(0,0,W,H,fill=1,stroke=0)
    c.setStrokeColor(colors.black); c.setLineWidth(.65); c.rect(x0,y0,bw,bh,fill=0,stroke=1)
    if os.path.exists(logo_path):
        c.drawImage(logo_path, x0+6, y0+10, width=100, height=104, preserveAspectRatio=True, anchor='c', mask='auto')
    c.setFillColor(GREEN)
    c.setFont('Helvetica-Bold', 15)
    c.drawCentredString(390, y0+84, 'ABASYN UNIVERSITY PESHAWAR')
    c.setFont('Helvetica', 14)
    c.drawCentredString(390, y0+59, 'DEPARTMENT OF COMPUTER')
    c.setFillColor(colors.black)
    c.setFont('Helvetica-Bold', 20)
    c.drawCentredString(W/2, 622, 'Assignment # ( 6 )')
    c.setLineWidth(.5); c.line(34, 608, W-34, 608)
    rows = [
        ('Subject :-', 'SOFTWARE TESTING'),
        ('Class / section :-', section),
        ('Submitted to :-', 'Sir Sheraz'),
        ('Registration NO# :-', roll),
        ('Submitted by :-', name),
    ]
    y = 558
    for label, value in rows:
        c.setFont('Helvetica-Bold', 9.5); c.drawString(132, y, label)
        c.drawString(289, y, value)
        y -= 55
    c.line(34, 245, W-34, 245)
    c.showPage()

def build_content(c):
    # Pages 2-5 deliberately parallel reference assignment's text and table density.
    def newpage():
        c.showPage()
    # Use ReportLab flowables within fixed, visually consistent content frames.
    pages = []
    p2 = [
        P('1- &nbsp; Program Pseudocode:', 'h2x'),
        P('INPUT membership<br/>INPUT purchaseAmount<br/>INPUT coupon<br/><br/>A = (membership == "Premium")<br/>B = (purchaseAmount &gt;= 10000)<br/>C = (coupon == TRUE)<br/><br/>IF (A AND (B OR C)) THEN<br/>&nbsp;&nbsp;&nbsp;&nbsp;PRINT "Discount Applicable"<br/>ELSE<br/>&nbsp;&nbsp;&nbsp;&nbsp;PRINT "No Discount"<br/>END IF', 'codebox'),
        P('Part 1: Decision Coverage (Branch Coverage)', 'h1x'),
        P('1. Identification of the Decision', 'h2x'),
        P('<b>Definition:</b> In structural white-box testing, a decision (or branch predicate) is a Boolean expression that determines which control-flow path executes.', 'bodyx'),
        P('In this pseudocode, the decision is the entire expression evaluated by the IF statement:', 'bodyx'),
        P('&nbsp;&nbsp;<b>Decision (D) = A AND (B OR C)</b>', 'bodyx'),
        P('This decision produces two mutually exclusive outcomes:', 'bodyx'),
        P('&bull;&nbsp; <b>Decision = TRUE (True Branch):</b> A is TRUE and either B or C is TRUE. The program prints "Discount Applicable".', 'bulletx'),
        P('&bull;&nbsp; <b>Decision = FALSE (False Branch):</b> A is FALSE, or both B and C are FALSE. The program prints "No Discount".', 'bulletx'),
        P('2. Test Case Table for Decision Coverage', 'h2x'),
        P('Decision coverage requires the overall decision to take both possible outcomes at least once. These two cases exercise the TRUE and FALSE branches.', 'bodyx'),
        table([[cell('Test Case ID',1),cell('Membership',1),cell('Purchase Amount',1),cell('Coupon Status',1),cell('Decision Result',1),cell('Expected Output',1),cell('Branch Covered',1)],
               [cell('TC_DC_01',1),cell('Premium'),cell('10000'),cell('FALSE'),cell('TRUE',1),cell('Discount Applicable'),cell('TRUE branch')],
               [cell('TC_DC_02',1),cell('Regular'),cell('12000'),cell('TRUE'),cell('FALSE',1),cell('No Discount'),cell('FALSE branch')]],
              [58,77,69,65,68,89,77]),
        Spacer(1,7),
        P('<b>Measurement &amp; Verification:</b> Decision Coverage = (decision outcomes tested / total decision outcomes) x 100% = (2 / 2) x 100% = <b>100%</b>. Both TRUE and FALSE branches are exercised.', 'smallx')
    ]
    p3 = [
        P('Part 2: Condition Coverage (Branch Condition Coverage)', 'h1x'),
        P('1. Identification of Individual Conditions', 'h2x'),
        P('<b>Definition:</b> A condition is an atomic Boolean predicate that evaluates independently to TRUE or FALSE. The decision contains three such conditions:', 'bodyx'),
        P('&bull;&nbsp; <b>Condition A:</b> membership == "Premium". TRUE for Premium membership; FALSE otherwise.', 'bulletx'),
        P('&bull;&nbsp; <b>Condition B:</b> purchaseAmount &gt;= Rs. 10,000. TRUE at or above Rs. 10,000; FALSE below Rs. 10,000.', 'bulletx'),
        P('&bull;&nbsp; <b>Condition C:</b> coupon == TRUE. TRUE when a valid promotional coupon is present; FALSE otherwise.', 'bulletx'),
        P('2. Test Case Table for Condition Coverage', 'h2x'),
        P('Condition coverage requires every individual condition to evaluate to TRUE and FALSE at least once. The following three test cases provide both outcomes for A, B, and C.', 'bodyx'),
        table([[cell('Test Case ID',1),cell('Membership',1),cell('Amount (Rs.)',1),cell('Coupon',1),cell('A',1),cell('B',1),cell('C',1),cell('Decision D',1),cell('Expected Output',1)],
               [cell('TC_CC_01',1),cell('Premium'),cell('12000'),cell('TRUE'),cell('TRUE',1),cell('TRUE',1),cell('TRUE',1),cell('TRUE',1),cell('Discount Applicable')],
               [cell('TC_CC_02',1),cell('Premium'),cell('8000'),cell('FALSE'),cell('TRUE',1),cell('FALSE',1),cell('FALSE',1),cell('FALSE',1),cell('No Discount')],
               [cell('TC_CC_03',1),cell('Regular'),cell('12000'),cell('TRUE'),cell('FALSE',1),cell('TRUE',1),cell('TRUE',1),cell('FALSE',1),cell('No Discount')]],
              [55,62,62,45,32,32,32,55,128]),
        Spacer(1,7),
        P('<b>Coverage check:</b> A is TRUE in TC_CC_01/02 and FALSE in TC_CC_03. B is TRUE in TC_CC_01/03 and FALSE in TC_CC_02. C is TRUE in TC_CC_01/03 and FALSE in TC_CC_02. Therefore all six required condition outcomes are covered: (6 / 6) x 100% = <b>100%</b>.', 'smallx')
    ]
    p4 = [
        P('Part 3: Decision/Condition Coverage (D/C Coverage)', 'h1x'),
        P('1. Designing a Test Suite Achieving Both Decision and Condition Coverage', 'h2x'),
        P('<b>Definition:</b> Decision/Condition Coverage (D/C Coverage) combines the two criteria. The test set must exercise both overall decision outcomes and both outcomes of each individual condition.', 'bodyx'),
        P('&bull;&nbsp; <b>Decision requirement:</b> D must evaluate to TRUE and FALSE at least once.', 'bulletx'),
        P('&bull;&nbsp; <b>Condition requirement:</b> A, B, and C must each evaluate to TRUE and FALSE at least once.', 'bulletx'),
        P('The three-case suite below covers the decision and every individual condition:', 'bodyx'),
        table([[cell('Test Case ID',1),cell('Membership',1),cell('Amount (Rs.)',1),cell('Coupon',1),cell('A',1),cell('B',1),cell('C',1),cell('Decision D',1),cell('Expected Output',1),cell('Branch',1)],
               [cell('TC_DCC_01',1),cell('Premium'),cell('12000'),cell('TRUE'),cell('TRUE',1),cell('TRUE',1),cell('TRUE',1),cell('TRUE',1),cell('Discount Applicable'),cell('THEN')],
               [cell('TC_DCC_02',1),cell('Premium'),cell('8000'),cell('FALSE'),cell('TRUE',1),cell('FALSE',1),cell('FALSE',1),cell('FALSE',1),cell('No Discount'),cell('ELSE')],
               [cell('TC_DCC_03',1),cell('Regular'),cell('12000'),cell('TRUE'),cell('FALSE',1),cell('TRUE',1),cell('TRUE',1),cell('FALSE',1),cell('No Discount'),cell('ELSE')]],
              [53,61,57,40,29,29,29,51,106,44]),
        Spacer(1,7),
        P('2. Traceability: How Each Test Case Contributes to Required Coverage', 'h2x'),
        table([[cell('Test Case',1),cell('Condition A contribution',1),cell('Condition B contribution',1),cell('Condition C contribution',1),cell('Decision contribution',1),cell('Cumulative coverage',1)],
               [cell('TC_DCC_01',1),cell('A = TRUE'),cell('B = TRUE'),cell('C = TRUE'),cell('D = TRUE'),cell('A/B/C: 1 of 2; D: 1 of 2')],
               [cell('TC_DCC_02',1),cell('A = TRUE'),cell('B = FALSE'),cell('C = FALSE'),cell('D = FALSE'),cell('A 1/2; B,C,D 2/2')],
               [cell('TC_DCC_03',1),cell('A = FALSE'),cell('B = TRUE'),cell('C = TRUE'),cell('D = FALSE'),cell('A/B/C/D: 2 of 2')]],
              [62,83,83,83,82,91]),
        Spacer(1,6),
        P('&bull;&nbsp; <b>Decision verification:</b> TRUE is covered by TC_DCC_01; FALSE is covered by TC_DCC_02 and TC_DCC_03. Decision coverage = 2/2 = 100%.', 'smallx'),
        P('&bull;&nbsp; <b>Condition verification:</b> A, B, and C each take both TRUE and FALSE across the three cases. Condition coverage = 6/6 = 100%.', 'smallx')
    ]
    p5 = [
        P('&bull;&nbsp; <b>Combined verification:</b> The same three cases satisfy both criteria, so Decision/Condition Coverage is complete at 100%.', 'smallx'),
        P('Part 4: Multiple Condition Coverage (MCC)', 'h1x'),
        P('1. All Possible Condition Combinations', 'h2x'),
        P('There are three independent Boolean conditions. The total number of combinations is 2^3 = <b>8</b>. Multiple Condition Coverage tests every combination exactly once.', 'bodyx'),
        P('2. Complete Combination Table', 'h2x'),
        table([[cell('Case #',1),cell('A: Premium',1),cell('B: Amount >= 10000',1),cell('C: Coupon valid',1),cell('Decision A AND (B OR C)',1),cell('Expected Output',1),cell('Result',1)],
               [cell('1',1),cell('TRUE'),cell('TRUE'),cell('TRUE'),cell('TRUE',1),cell('Discount Applicable'),cell('Discount')],
               [cell('2',1),cell('TRUE'),cell('TRUE'),cell('FALSE'),cell('TRUE',1),cell('Discount Applicable'),cell('Discount')],
               [cell('3',1),cell('TRUE'),cell('FALSE'),cell('TRUE'),cell('TRUE',1),cell('Discount Applicable'),cell('Discount')],
               [cell('4',1),cell('TRUE'),cell('FALSE'),cell('FALSE'),cell('FALSE',1),cell('No Discount'),cell('No discount')],
               [cell('5',1),cell('FALSE'),cell('TRUE'),cell('TRUE'),cell('FALSE',1),cell('No Discount'),cell('No discount')],
               [cell('6',1),cell('FALSE'),cell('TRUE'),cell('FALSE'),cell('FALSE',1),cell('No Discount'),cell('No discount')],
               [cell('7',1),cell('FALSE'),cell('FALSE'),cell('TRUE'),cell('FALSE',1),cell('No Discount'),cell('No discount')],
               [cell('8',1),cell('FALSE'),cell('FALSE'),cell('FALSE'),cell('FALSE',1),cell('No Discount'),cell('No discount')]],
              [42,66,102,77,112,111,62]),
        Spacer(1,7),
        P('<b>Interpretation:</b> Discount is applicable only when A is TRUE and at least one of B or C is TRUE. Thus combinations 1, 2, and 3 produce "Discount Applicable"; combinations 4 through 8 produce "No Discount".', 'smallx'),
        P('Part 5: Coverage Calculation and Comparison', 'h1x'),
        table([[cell('Technique',1),cell('Coverage calculation',1),cell('Coverage',1)],
               [cell('Decision Coverage',1),cell('(2 decision outcomes tested / 2 total) x 100%'),cell('100%')],
               [cell('Condition Coverage',1),cell('(6 condition outcomes tested / 6 total) x 100%'),cell('100%')],
               [cell('Decision/Condition Coverage',1),cell('Both decision outcomes and all six condition outcomes'),cell('100%')],
               [cell('Multiple Condition Coverage',1),cell('(8 combinations tested / 8 possible) x 100%'),cell('100%')]],
              [132,274,166]),
        Spacer(1,5),
        P('<b>Coverage technique comparison:</b>', 'h2x'),
        P('&bull;&nbsp; <b>Decision coverage</b> checks that the whole IF expression takes each outcome (TRUE and FALSE).', 'smallx'),
        P('&bull;&nbsp; <b>Condition coverage</b> checks that each atomic condition A, B, and C independently takes both TRUE and FALSE values.', 'smallx'),
        P('&bull;&nbsp; <b>Decision/Condition coverage</b> requires both decision outcomes and both outcomes of every individual condition in one test suite.', 'smallx'),
        P('&bull;&nbsp; <b>Multiple Condition Coverage</b> tests every possible combination of individual condition values; for three conditions it requires eight cases.', 'smallx'),
        P('MCC subsumes individual condition outcome coverage and decision coverage for this decision, but requires more tests. Decision/Condition coverage uses fewer tests than MCC while explicitly checking the two stated criteria.', 'smallx')
    ]
    return [p2,p3,p4,p5]

def make_pdf(student):
    name, roll, sec = student
    safe = ''.join(ch for ch in name.lower().replace(' ','-') if ch.isalnum() or ch=='-')
    path = os.path.join(OUT, f'ST-Assign-5-{roll}-{safe}.pdf')
    c = canvas.Canvas(path, pagesize=(W,H), pageCompression=1)
    c.setTitle(f'Structural Coverage Assignment - {name} - {roll}')
    c.setAuthor(name)
    cover(c, student)
    for idx, story in enumerate(build_content(c)):
        # generous margins consistent with the reference; pages 2-5 remain single pages
        frame = Frame(35, 35, W-70, H-58, leftPadding=4, rightPadding=4, topPadding=4, bottomPadding=4, showBoundary=0)
        frame.addFromList(story, c)
        if story:
            raise RuntimeError(f'Content overflow in page {idx+2}: {len(story)} flowables remain')
        c.showPage()
    c.save()
    return path

if __name__ == '__main__':
    for s in STUDENTS:
        print(make_pdf(s))
