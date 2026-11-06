#!/usr/bin/env python3
"""Build the proposal PDF from the editable Markdown and bundled preview.

Optional authoring dependency: pip install reportlab
Run from any directory: python build_proposal_pdf.py
The interactive prototype itself has no dependency on this script or ReportLab.
"""

from pathlib import Path
import html
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Flowable, Frame, PageBreak, PageTemplate,
    Paragraph, Spacer, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parent.parent
INPUT = ROOT / '01-Product/PROJECT-PROPOSAL.md'
OUTPUT = ROOT / '01-Product/PROJECT-PROPOSAL.pdf'
PREVIEW = ROOT / '03-Design/Previews/gylt-screen-overview.jpg'
PAGE_W, PAGE_H = A4
MARGIN = 49
WIDTH = PAGE_W - 2 * MARGIN
PAPER = colors.HexColor('#f7f6f2')
INK = colors.HexColor('#242722')
ORANGE = colors.HexColor('#ff6548')
GREEN = colors.HexColor('#45634a')
MUTED = colors.HexColor('#65705b')
LINE = colors.HexColor('#dedfd5')
PALE = colors.HexColor('#e9ede3')

font_dir = Path('/usr/share/fonts/truetype/dejavu')
if (font_dir / 'DejaVuSans.ttf').exists():
    pdfmetrics.registerFont(TTFont('GYLT', str(font_dir / 'DejaVuSans.ttf')))
    pdfmetrics.registerFont(TTFont('GYLT-Bold', str(font_dir / 'DejaVuSans-Bold.ttf')))
    pdfmetrics.registerFontFamily('GYLT', normal='GYLT', bold='GYLT-Bold',
                                  italic='GYLT', boldItalic='GYLT-Bold')
    FONT, BOLD = 'GYLT', 'GYLT-Bold'
else:
    FONT, BOLD = 'Helvetica', 'Helvetica-Bold'


def clean(value):
    return (value.replace('\u2014', ' - ').replace('\u2013', '-')
            .replace('\u2011', '-').replace('\u2019', "'")
            .replace('\u2018', "'").replace('\u201c', '"')
            .replace('\u201d', '"').replace('\u2026', '...')
            .replace('\u00a0', ' '))


def inline(value):
    """A deliberately small Markdown inline renderer, with clickable URLs."""
    value = clean(value)
    token_re = re.compile(r'(\[[^\]]+\]\([^)]+\)|https?://[^\s<>]+|`[^`]+`|\*\*[^*]+\*\*)')
    result, start = [], 0
    for match in token_re.finditer(value):
        result.append(html.escape(value[start:match.start()]))
        token = match.group(0)
        if token.startswith('**'):
            result.append('<b>' + html.escape(token[2:-2]) + '</b>')
        elif token.startswith('`'):
            result.append('<font name="Courier" size="9">' + html.escape(token[1:-1]) + '</font>')
        elif token.startswith('['):
            label, href = re.fullmatch(r'\[([^\]]+)\]\(([^)]+)\)', token).groups()
            result.append('<link href="' + html.escape(href, quote=True) + '" color="#45634a">'
                          + html.escape(label) + '</link>')
        else:
            url = token.rstrip('.,;')
            result.append('<link href="' + html.escape(url, quote=True) + '" color="#45634a">'
                          + html.escape(url) + '</link>' + html.escape(token[len(url):]))
        start = match.end()
    result.append(html.escape(value[start:]))
    return ''.join(result)


styles = {
    'body': ParagraphStyle('body', fontName=FONT, fontSize=9.8, leading=13.2,
        textColor=INK, spaceAfter=6, splitLongWords=1, allowWidows=0, allowOrphans=0),
    'h2': ParagraphStyle('h2', fontName=BOLD, fontSize=17.5, leading=22,
        textColor=INK, spaceBefore=10, spaceAfter=8, keepWithNext=1),
    'h3': ParagraphStyle('h3', fontName=BOLD, fontSize=12, leading=17,
        textColor=INK, spaceBefore=11, spaceAfter=7, keepWithNext=1),
    'bullet': ParagraphStyle('bullet', fontName=FONT, fontSize=9.8, leading=13.2,
        textColor=INK, spaceAfter=4, leftIndent=12, firstLineIndent=0,
        bulletIndent=0, bulletFontName=BOLD, bulletFontSize=9.8),
    'table': ParagraphStyle('table', fontName=FONT, fontSize=8.7, leading=12.4,
        textColor=INK, spaceAfter=0, splitLongWords=1),
    'th': ParagraphStyle('th', fontName=BOLD, fontSize=8.5, leading=12,
        textColor=colors.white, spaceAfter=0),
    'source': ParagraphStyle('source', fontName=FONT, fontSize=8.9, leading=13.1,
        textColor=INK, spaceAfter=8, leftIndent=17, firstLineIndent=-17,
        splitLongWords=1),
}


class Cover(Flowable):
    def __init__(self):
        Flowable.__init__(self)
        self.width, self.height = WIDTH, 690

    def draw(self):
        c = self.canv
        c.saveState()
        c.translate(-MARGIN, -(PAGE_H - 66 - self.height))
        c.setFillColor(PAPER)
        c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
        c.setFillColor(INK)
        c.setFont(BOLD, 45)
        c.drawString(49, 756, 'gylt')
        c.setFillColor(ORANGE)
        c.drawString(133, 756, '.')
        c.setFillColor(MUTED)
        c.setFont(BOLD, 8)
        c.drawRightString(PAGE_W - 49, 780, 'GET YOUR LIFE TOGETHER')
        c.setFont(FONT, 8)
        c.drawRightString(PAGE_W - 49, 765, 'CONCEPT + DEVELOPER HANDOFF')
        c.setStrokeColor(LINE)
        c.line(49, 737, PAGE_W - 49, 737)
        c.setFillColor(ORANGE)
        c.setFont(BOLD, 9)
        c.drawString(49, 709, 'PROJECT PROPOSAL')
        c.setFillColor(INK)
        c.setFont(BOLD, 34)
        c.drawString(47, 661, 'A coach that gets')
        c.drawString(47, 619, 'you moving.')
        c.setFont(FONT, 11)
        c.drawString(49, 586, 'Direct voice coaching. User-approved distraction controls.')
        c.drawString(49, 568, 'A deliberate path from intention to action.')
        c.drawImage(str(PREVIEW), 49, 201, width=WIDTH, height=WIDTH * 936 / 1363,
                    preserveAspectRatio=True, mask='auto')
        c.setFillColor(MUTED)
        c.setFont(FONT, 8)
        c.drawString(49, 186, 'Prototype preview: Today, intervention and app block.')
        c.setStrokeColor(LINE)
        c.line(49, 165, PAGE_W - 49, 165)
        c.setFillColor(INK)
        c.setFont(BOLD, 8)
        c.drawString(49, 144, 'BYOK AI + INDEPENDENT TTS')
        c.drawRightString(PAGE_W - 49, 144, '6 NOVEMBER 2026')
        c.setFont(FONT, 8)
        c.setFillColor(MUTED)
        c.drawString(49, 122, 'Status: Concept and developer handoff; recommendations awaiting product validation.')
        c.drawString(49, 107, 'Research date: 6 November 2026')
        url = 'https://gylt-prototype.stekz-3007.chatgpt.site/'
        c.setFillColor(GREEN)
        c.drawString(49, 86, 'Working prototype: ' + url)
        c.linkURL(url, (49, 83, PAGE_W - 49, 96), relative=0, thickness=0)
        c.setFillColor(MUTED)
        c.setFont(FONT, 7)
        c.drawString(49, 49, 'PROPOSAL / 01')
        c.restoreState()


def page_decoration(c, doc):
    if doc.page == 1:
        return
    c.saveState()
    c.setFillColor(PAPER)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillColor(INK)
    c.setFont(BOLD, 20)
    c.drawString(MARGIN, PAGE_H - 38, 'gylt')
    c.setFillColor(ORANGE)
    c.drawString(MARGIN + 37, PAGE_H - 38, '.')
    c.setFillColor(MUTED)
    c.setFont(BOLD, 7.5)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 32, 'PROJECT PROPOSAL')
    c.setFont(FONT, 7)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 44, 'CONCEPT HANDOFF / 6 NOVEMBER 2026')
    c.setStrokeColor(LINE)
    c.line(MARGIN, PAGE_H - 55, PAGE_W - MARGIN, PAGE_H - 55)
    c.line(MARGIN, 44, PAGE_W - MARGIN, 44)
    c.setFillColor(MUTED)
    c.setFont(FONT, 7)
    c.drawString(MARGIN, 29, 'GET YOUR LIFE TOGETHER')
    c.drawRightString(PAGE_W - MARGIN, 29, f'{doc.page:02d}')
    c.restoreState()


class ProposalDoc(BaseDocTemplate):
    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph) and flowable.style.name == 'h2':
            title = flowable.getPlainText()
            key = 'section-' + re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title, key, level=0)


def table_from(rows):
    parsed = [[x.strip() for x in row.strip().strip('|').split('|')] for row in rows]
    parsed = [row for row in parsed if not all(re.fullmatch(r':?-+:?', c) for c in row)]
    data = [[Paragraph(inline(cell), styles['th' if i == 0 else 'table'])
             for cell in row] for i, row in enumerate(parsed)]
    count = len(data[0])
    widths = [WIDTH * .18, WIDTH * .35, WIDTH * .47] if count == 3 else [WIDTH / count] * count
    t = Table(data, colWidths=widths, repeatRows=1, hAlign='LEFT')
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), INK),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, PALE]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LINEBELOW', (0, 1), (-1, -1), .35, LINE),
    ]))
    return t


def main():
    lines = INPUT.read_text(encoding='utf-8').splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith('## 1. '))
    lines = lines[start:]
    story = [Cover(), PageBreak()]
    page_sections = {'3', '5', '7', '9', '11'}
    source_mode = False
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('## '):
            heading = line[3:]
            num = re.match(r'(\d+)\.', heading)
            if (num and num.group(1) in page_sections) or heading == 'Source notes':
                story.append(PageBreak())
            source_mode = heading == 'Source notes'
            story.append(Paragraph(inline(heading), styles['h2']))
            i += 1
            continue
        if line.startswith('### '):
            story.append(Paragraph(inline(line[4:]), styles['h3']))
            i += 1
            continue
        if line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                rows.append(lines[i])
                i += 1
            story.extend([table_from(rows), Spacer(1, 10)])
            continue
        if line.startswith('- '):
            story.append(Paragraph(inline(line[2:]), styles['bullet'], bulletText='-'))
            i += 1
            continue
        if source_mode and re.match(r'^\d+\. ', line):
            story.append(Paragraph(inline(line), styles['source']))
            i += 1
            continue
        para = [line]
        i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||- )', lines[i].strip()):
            if source_mode and re.match(r'^\d+\. ', lines[i].strip()):
                break
            para.append(lines[i].strip())
            i += 1
        story.append(Paragraph(inline(' '.join(para)), styles['body']))

    doc = ProposalDoc(str(OUTPUT), pagesize=A4, leftMargin=MARGIN, rightMargin=MARGIN,
                      topMargin=70, bottomMargin=59, title='GYLT - Project Proposal',
                      author='GYLT project', subject='Concept and developer handoff, 6 November 2026')
    frame = Frame(MARGIN, 59, WIDTH, PAGE_H - 129, leftPadding=0, rightPadding=0,
                  topPadding=0, bottomPadding=0, id='main')
    doc.addPageTemplates(PageTemplate(id='proposal', frames=[frame], onPage=page_decoration))
    doc.build(story)
    print(OUTPUT)


if __name__ == '__main__':
    main()
