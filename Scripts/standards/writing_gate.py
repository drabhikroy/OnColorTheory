"""
House writing standards check.

Runs over source, documentation, and scripts. Third party notices are skipped,
because that text is reproduced verbatim from upstream licenses and must not be
edited to suit a local style rule.

  no em dashes and no en dashes anywhere
  no contractions
  no banned lexicon
  no historical or version-referencing comments
  no British spelling in prose, only in a real API name or a cited title

Exit status is non-zero on any finding, so this runs as a build gate.
"""

import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
EXTENSIONS = (".swift", ".md", ".sh", ".json", ".plist", ".py", ".html", ".svg")
# License texts and third-party notices are reproduced word for word. Editing
# one to satisfy a house style rule would change its legal meaning, so the gate
# does not read them.
SKIP_FILES = {"THIRD_PARTY_NOTICES.md", "OFL.txt", "SwiftMath-LICENSE.txt",
              "LICENSE.md", "LICENSE", "LICENSE.txt",
              "writing_gate.py"}  # this file names the terms it looks for
# A local build copies a dependency's own resource bundle into Build/,
# including scripts that dependency ships with its own text. Walking into it
# means reading someone else's code as if it were this project's prose, the
# same reason license text is skipped above.
SKIP_DIRS = {".git", ".build", "dist", "Build", "DerivedData"}

EM = "\u2014"
EN = "\u2013"

BANNED = """
Actionable Adept Bolster Commendable Delve Encompass Enhance Ensure Equip
Esteemed Facilitate Foster Grasp Guarantee Hone Instrumental Intricate
Invaluable Journey Landscape Leverage Maximize Meticulous Multifaceted Nuance
Nuanced Passionate Pivotal Plethora Realm Rigorous Robust Seamlessly Showcasing
Streamline Strengthen Strive Synergy Techniques Transformative Translate Tweak
Uncover Utilize Vital
""".split()

# Words that are Swift or platform vocabulary rather than prose choices.
ALLOWED_IN_CODE = {"align", "alignment", "intersection", "enable", "isEnabled"}

# House style is American English throughout, so British spellings are a
# defect in prose the same way a banned word or a contraction is. The list
# covers the productive rules (-our, -re, -ise/-isation, doubled consonants
# before a suffix, -t past tense forms, ae/oe reduced to e) plus the common
# irregular pairs, rather than a handful of examples remembered by hand.
BRITISH_SPELLINGS = """
abridgement acknowledgement aeroplane aluminium anaesthesia anaesthesiologist anaesthetic analogue
apologisation apologise apologised apologising archaeological artefact authorisation authorise
authorised authorising axe behaviour behavioural burnt calibre cancelled
cancelling capitalisation capitalise capitalised capitalising catalogue catalogued cataloguing
categorisation categorise categorised categorising centimetre centimetres centre centred
centring characterise characterised characterising cheque civilisation civilise civilised
civilising colonisation colonise colonised colonising colour coloured colourful
colouring colourless colourway counselled counselling customisation customise customised
customising defence dialogue dialogued dialoguing diarrhoea discolour discoloured
discolouring draught draughty dreamt emphasise emphasised emphasising encyclopaedia
endeavour endeavoured endeavouring enrol enrolled enrolling enrolment equalisation
equalise equalised equalising familiarisation familiarise familiarised familiarising favour
favourable favourably favoured favouring favourite favourites fibre finalisation
finalise finalised finalising flavour flavoured flavouring foetal foetus
fulfil fulfilled fulfilling fulfilment generalisation generalise generalised generalising
grey gynaecology haemoglobin haemorrhage harbour harboured harbouring harmonisation
harmonise harmonised harmonising honour honourable honourably honoured honouring
humour humoured humouring humourless idealisation idealise idealised idealising
initialisation initialise initialised initialising instalment jewellery judgement kerb
kilometre kilometres knelt labelled labelling labour laboured labouring
lacklustre leapt learnt leukaemia levelled levelling licence litre
localisation localise localised localising lustre manoeuvrable manoeuvre manoeuvring
maximisation maximise maximised maximising mediaeval memorise memorised memorising
metre metres millimetre millimetres minimisation minimise minimised minimising
modelled modelling modernisation modernise modernised modernising mould moulded
moulding mum nanometre nanometres neighbour neighboured neighbourhood neighbouring
neighbourly neutralisation neutralise neutralised neutralising normalisation normalise normalised
normalising odour oesophagus oestrogen offence optimisation optimise optimised
optimising organisation organisational organisations organise organised organiser organisers
organising paediatric paediatrician parlour patronise patronised patronising personalisation
personalise personalised personalising plough ploughed ploughing practise pretence
prioritisation prioritise prioritised prioritising programme pyjamas rancour randomisation
randomise randomised randomising realisation realise realised realising recognisable
recognise recognised recognising regularisation regularise regularised regularising rigour
rumour sanitisation sanitise sanitised sanitising saviour sceptic sceptical
scepticism serialisation serialise serialised serialising signalled signalling skilful
smelt socialisation socialise socialised socialising specialisation specialise specialised
specialising speciality spelt spilt splendour spoilt stabilisation stabilise
stabilised stabilising standardisation standardise standardised standardising storey storeys
succour summarisation summarise summarised summarising symbolisation symbolise symbolised
symbolising synchronisation synchronise synchronised synchronising theatre theatregoer travelled
traveller travelling tumour tyre utilisation utilise utilised utilising
valour vapour vigour visualisation visualise visualised visualising whisky
wilful woollen
""".split()

# Two words on that list are also the literal spelling of a real Foundation
# API. URLError.Code.cancelled is Apple's own case name, so a line naming it
# is not a spelling choice and must not be rewritten or the build breaks.
API_SPELLING_EXCEPTIONS = {"cancelled", "cancelling"}
API_SPELLING_MARKERS = (".cancelled", "URLError", "case cancelled")

# Exact phrases already reviewed and confirmed to be someone else's title
# rather than this app's prose: CIE publishes its own standards under a
# British spelled title, and citing that title accurately means reproducing
# the spelling CIE chose, the same way a quotation preserves its source's
# wording. Adding to this list is a deliberate, visible decision, which is
# the point, since a citation exemption should never pass silently.
CITATION_EXEMPT_SPELLINGS = (
    "CIEDE2000 colour-difference formula",
    "The CIE 2016 Colour Appearance Model for Colour Management Systems",
)

URL_TOKEN = re.compile(r"https?://\S+")

# A term inside backticks is being named rather than used, which is how a review
# note or a changelog refers to the wording it replaced. Those spans are removed
# before the lexicon check, though the dash and contraction checks still see the
# whole line.
INLINE_CODE = re.compile(r"`[^`]*`")

# "Drawn" is allowed for actual rendering and banned for the derivation sense.
# That sense is carried by the preposition, so the phrase is what gets checked
# rather than the word. "The bar is drawn to scale" and "drawn on a track" both
# describe rendering and pass. "Values drawn from the palette" and "the estimate
# draws on prior work" mean pulled or derived and do not.
DERIVATION = re.compile(
    r"\b(?:draw(?:n|ing)?\s+(?:from|upon)|draw(?:s|ing)\s+on)\b",
    re.IGNORECASE,
)

CONTRACTION = re.compile(
    r"\b(?:do|does|did|is|are|was|were|has|have|had|could|would|should|will|can|"
    r"it|that|there|let|they|we|you|he|she|what|here|who)n?['\u2019](?:t|s|re|ve|ll|d|m)\b",
    re.IGNORECASE,
)

HISTORICAL = re.compile(
    r"^\s*(?://|///|#\s)\s*.*\b(?:previously|formerly|used to|no longer|as of \d|"
    r"legacy|deprecated|TODO|FIXME|HACK|XXX|v\d+\.\d+|version \d+\.\d+)\b",
    re.IGNORECASE,
)


def files():
    for root, dirs, names in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in names:
            if name in SKIP_FILES or not name.endswith(EXTENSIONS):
                continue
            yield os.path.join(root, name)


def check(path):
    found = []
    relative = os.path.relpath(path, ROOT)
    for number, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        if EM in line:
            found.append((relative, number, "em dash", line.strip()))
        if EN in line:
            found.append((relative, number, "en dash", line.strip()))
        match = CONTRACTION.search(line)
        if match:
            found.append((relative, number, "contraction " + match.group(0), line.strip()))
        if HISTORICAL.match(line):
            found.append((relative, number, "historical comment", line.strip()))
        match = DERIVATION.search(line)
        if match:
            found.append((relative, number, "derivation sense of " + match.group(0), line.strip()))
        prose = INLINE_CODE.sub("``", line)
        for word in BANNED:
            if word.lower() in ALLOWED_IN_CODE and relative.endswith(".swift"):
                continue
            if re.search(r"\b" + word + r"(s|es|ed|ing|ment|ly|ance|ence)?\b", prose, re.I):
                found.append((relative, number, "banned term " + word, line.strip()))
        if any(exempt in line for exempt in CITATION_EXEMPT_SPELLINGS):
            continue
        url_spans = [m.span() for m in URL_TOKEN.finditer(line)]
        for word in BRITISH_SPELLINGS:
            for match in re.finditer(r"\b" + re.escape(word) + r"\b", line, re.IGNORECASE):
                if any(start <= match.start() < end for start, end in url_spans):
                    continue
                lower = match.group(0).lower()
                if lower in API_SPELLING_EXCEPTIONS and any(marker in line for marker in API_SPELLING_MARKERS):
                    continue
                found.append((relative, number, "British spelling " + match.group(0), line.strip()))
    return found


def main():
    findings = []
    for path in files():
        findings.extend(check(path))
    for relative, number, reason, line in findings:
        print("%s:%d  %s\n    %s" % (relative, number, reason, line[:110]))
    print()
    if findings:
        print("%d findings" % len(findings))
        return 1
    print("Writing standards pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
