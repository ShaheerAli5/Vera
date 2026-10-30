from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, PageBreak
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import HexColor

out = r'C:\Users\Shaheer\Documents\GitHub\Vera\output\pdf\Shaheer-resume-updated.pdf'
profile='https://github.com/ShaheerAli5'
navy=HexColor('#172642'); purple=HexColor('#6254d9'); muted=HexColor('#56647a'); pale=HexColor('#f3f3f8'); link=HexColor('#315caa')
pdfmetrics.registerFont(TTFont('Arial','C:\\Windows\\Fonts\\arial.ttf'))
pdfmetrics.registerFont(TTFont('Arial-Bold','C:\\Windows\\Fonts\\arialbd.ttf'))
pdfmetrics.registerFont(TTFont('Arial-Italic','C:\\Windows\\Fonts\\ariali.ttf'))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='Arial-Bold', italic='Arial-Italic', boldItalic='Arial-Bold')
doc=SimpleDocTemplate(out,pagesize=A4,rightMargin=17*mm,leftMargin=17*mm,topMargin=14*mm,bottomMargin=17*mm,title='Muhammad Shaheer Ali - Resume',author='Muhammad Shaheer Ali')
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='Name',fontName='Arial-Bold',fontSize=22,leading=25,textColor=navy,spaceAfter=2))
styles.add(ParagraphStyle(name='Headline',fontName='Arial',fontSize=10.2,leading=13,textColor=purple,spaceAfter=5))
styles.add(ParagraphStyle(name='Contact',fontName='Arial',fontSize=8,leading=11,textColor=muted,spaceAfter=8))
styles.add(ParagraphStyle(name='Section',fontName='Arial-Bold',fontSize=10.2,leading=13,textColor=navy,spaceBefore=6,spaceAfter=4,keepWithNext=True))
styles.add(ParagraphStyle(name='Body2',fontName='Arial',fontSize=8.25,leading=11,textColor=HexColor('#242a35'),spaceAfter=3))
styles.add(ParagraphStyle(name='Role',fontName='Arial-Bold',fontSize=8.6,leading=11,textColor=navy))
styles.add(ParagraphStyle(name='Meta',fontName='Arial',fontSize=7.6,leading=9.5,textColor=muted))
styles.add(ParagraphStyle(name='Bullet2',fontName='Arial',fontSize=8.1,leading=10.5,leftIndent=10,firstLineIndent=-7,textColor=HexColor('#242a35'),spaceAfter=1))
styles.add(ParagraphStyle(name='Small',fontName='Arial',fontSize=7.8,leading=10,textColor=HexColor('#242a35'),spaceAfter=2))
P=lambda s,style='Body2': Paragraph(s,styles[style])
story=[]
story += [P('MUHAMMAD SHAHEER ALI','Name'),P('Flutter Developer | Mobile Application Developer | Software Engineer','Headline')]
story += [P('Peshawar, Pakistan &nbsp;|&nbsp; +92 333 8738974 &nbsp;|&nbsp; <link href="mailto:Shaheeralidev22@gmail.com" color="#315caa">Shaheeralidev22@gmail.com</link> &nbsp;|&nbsp; <link href="https://www.linkedin.com/in/muhammad-shaheer-ali-61aa6535b" color="#315caa">LinkedIn</link> &nbsp;|&nbsp; <link href="%s" color="#315caa">GitHub</link> &nbsp;|&nbsp; <link href="https://shaheer-portfolio-psi.vercel.app/" color="#315caa">Portfolio</link>'%profile,'Contact')]
story += [P('PROFESSIONAL SUMMARY','Section'),P('Flutter-focused Mobile Application Developer and Software Engineering student with 2+ years of hands-on experience building cross-platform applications. Works with Dart, Flutter, BLoC, Clean Architecture, REST APIs, Firebase, offline persistence, and responsive UI implementation. Contributes across feature development, third-party integrations, debugging, and collaboration with backend and design teams.')]
story += [P('TECHNICAL SKILLS','Section')]
rows=[[P('<b>Mobile</b><br/>Flutter, Android, Firebase, Firestore, Google Maps, NFC, QR and barcode scanning','Small'),P('<b>Architecture</b><br/>BLoC, Provider, Clean Architecture, state management, offline-first design','Small')],
[P('<b>Backend and data</b><br/>REST APIs, Dio, Socket.IO, Node.js, Hive, MySQL, Firebase Realtime Database','Small'),P('<b>Tools</b><br/>Git, GitHub, Android Studio, VS Code, Postman, Figma','Small')]]
t=Table(rows,colWidths=[86*mm,86*mm],hAlign='LEFT'); t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),pale),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),3)])); story += [t, P('PROFESSIONAL EXPERIENCE','Section')]
def role(title,company,dates,meta,bullets):
    head=Table([[P(f'{title} | {company}','Role'),P(dates,'Meta')],[P(meta,'Meta'),'']],colWidths=[130*mm,42*mm],hAlign='LEFT')
    head.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('ALIGN',(1,0),(1,0),'RIGHT'),('SPAN',(0,1),(1,1)),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),0),('TOPPADDING',(0,0),(-1,-1),0),('BOTTOMPADDING',(0,0),(-1,-1),1)]))
    items=[head]
    items.extend(P('• '+b,'Bullet2') for b in bullets)
    items.append(Spacer(1,3))
    return KeepTogether(items)
story += [role('Mobile Application Developer','Aptech Media','Apr 2026 - Present','Peshawar | Flutter, Dart, REST APIs, Firebase',[
'Develop and maintain Flutter applications from responsive interface implementation through REST API integration.',
'Implement production features and resolve build, runtime, and rendering issues across Android and iOS workflows.',
'Collaborate with backend and design teams to translate requirements into maintainable application features.'])]
story += [role('Mobile Application Developer','SaiKet Systems','Feb 2025 - May 2025','Remote | Flutter, Dart, REST APIs',[
'Built Flutter modules that integrated REST APIs and third-party services for client projects.',
'Implemented responsive interface components aligned with supplied design specifications.'])]
story += [role('Mobile Application Developer','CodeAlpha and ZafixTech','Oct 2024 - Dec 2024','Remote | Flutter, Dart, REST APIs',[
'Developed reusable Flutter screens and application features across two remote engagements.',
'Connected interface flows to REST APIs with an emphasis on clear, maintainable implementation.'])]
story += [P('SELECTED PROJECTS','Section')]
def project(name,stack,bullets):
    return KeepTogether([P(f'<u>{name}</u> &nbsp;|&nbsp; {stack}','Small')]+[P('• '+b,'Bullet2') for b in bullets]+[Spacer(1,2)])
story += [project('Mr. Valet','Flutter, BLoC, Clean Architecture, Dio, Socket.IO, Firebase',[
"Developed role-based mobile workflows for Al Sharqi Company's valet operations in Qatar, covering vehicle check-in, secure key handling, status updates, payments, and retrieval.",
'Integrated QR and NFC interactions, Firebase notifications, Google Maps, SADAD payments, attendance, incident reporting, memberships, vouchers, and thermal printing.'])]
story += [project('Chatting App','Flutter, Firebase Authentication, Firestore, Android flavors',[
'Implemented authentication, one-to-one messaging, group conversations, and Firestore-backed real-time updates.',
'Configured multiple Android flavors and stabilized build and runtime behavior across variants.'])]
story += [PageBreak(),P('SELECTED PROJECTS CONTINUED','Section')]
story += [project('Learning Management System','Flutter, Dart, Hive',['Built an offline-first learning application with local persistence and responsive Flutter layouts.'])]
story += [project('Personal Finance Manager','Flutter, Hive, Provider',['Created income, expense, budget, and goal workflows with Provider-based state management and local storage.'])]
story += [P('EDUCATION','Section')]
head=Table([[P('BS Computer Software Engineering','Role'),P('2023 - 2027 (Expected)','Meta')],[P('Abasyn University, Peshawar','Meta'),'']],colWidths=[130*mm,42*mm]); head.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('ALIGN',(1,0),(1,0),'RIGHT'),('SPAN',(0,1),(1,1)),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),0),('TOPPADDING',(0,0),(-1,-1),0),('BOTTOMPADDING',(0,0),(-1,-1),0)])); story += [head]
story += [P('<b>Relevant coursework:</b> Software Engineering, Data Structures and Algorithms, Mobile Application Development, Python Programming','Small')]
story += [P('<b>Final Year Project:</b> Stump Champions Turf - planned indoor cricket booking and management system with Flutter desktop and mobile clients, user and administrative roles, slot reservations, tournament management, dashboards, and role-based access control.','Small')]
story += [P('CERTIFICATIONS','Section')]
story += [P('• Flutter App Development - Arfa Kareem Incubator, Peshawar<br/>• AI Fundamentals - Huawei AI Course<br/>• Flutter, Dart, Python and Android Studio training - issuing organization requires confirmation','Small')]
story += [P('LEADERSHIP','Section')]
story += [P('• Vice President, Aspire Student Club, Abasyn University | Oct 2024 - Dec 2025 - Coordinated events, supported the leadership team, and contributed to member engagement.<br/>• Event Organizer, Microsoft Learn Student Ambassadors - AUP | Nov 2024 - Feb 2026 - Planned technical workshops and supported hands-on developer learning.','Small')]
story += [P('ADDITIONAL PROJECTS AND LANGUAGES','Section')]
story += [P('Additional project work includes KP Travel, Bus Routing App, 4-Paws, and an AI Chatbot. Languages: English (professional working proficiency) and Urdu (native).','Small')]
def footer(canvas,doc):
    canvas.saveState(); canvas.setFont('Arial',7); canvas.setFillColor(muted); canvas.drawRightString(A4[0]-17*mm,9*mm,f'MUHAMMAD SHAHEER ALI  |  {doc.page}'); canvas.restoreState()
doc.build(story,onFirstPage=footer,onLaterPages=footer)
print(out)


