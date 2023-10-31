# Brain Board ][
Updated "Brain Board" originally designed by Mike Willegal

![s-l500](https://user-images.githubusercontent.com/20172602/217665056-29c14f80-c498-4fa3-8919-e9a7e37e5e0b.jpeg)

The Brain Board II is a slot card for the Apple II, II+, and IIe computers. It allows use of the Wozaniam pack to mimic Apple-1 Operation (including Cassette interface), as well as provides a user ROM area which can be used to boot Integer BASIC among other possibilities. 

The original documentation for the card can be found on Mike Willegal's site: http://www.willegal.net/appleii/brainboard.htm

The BOM on page BB:3 should be appended from the original design as follows (This information is reflected in the PARTS LIST section below):

Include one more 10K resistor. (5 in total)

The 6 non-polarized capacitors shown on this page should be .1uf, not .01uf. 

Lastly, it is imperative to use a 27C512 or SST 27SF512 with this design in place of the 27c256 EPROM.


Normal operation is the same if you follow the quick start guide from the original Brain Board manual. bb-v5_1.pdf is provided in this repository, but for convenience, these are the 2 most common settings. 

# SETTING 1: QUICK START - Use ApplesoftInteger.BIN or QuickStart.BIN

DIPS:
1,3,5,8: ON

4,6,7 OFF

When using ApplesoftInteger.BIN:
DIP2 doesn't matter if you use the ApplesoftInteger.bin ROM, since the wozaniam pack is in the same relative location in both banks that this DIP controls.
In this mode, the back toggle will switch between normal system ROM, and the Wozaniam (apple 1 emulation) mode. 
If you don't need Applesoft on the ROM card (i.e. you have a IIe with good ROMS on the motherboard), you can use the QuickStart.ROM. See more on Rom Layout below. 

When using QuickStart.BIN
DIP2 changes the visible low bank to the brain board between integer BASIC and Wozaniam / Apple 1 mode. 
In this mode, the back toggle will switch between normal system ROM, and the Wozaniam (apple 1 emulation) mode OR Integer BASIC, depending on the position of DIP 2. This makes the card a handy Integer BASIC ROM card with an optional Apple 1 mode.

# SETTING 2: APPLESOFT / INTEGER BASIC - Use ApplesoftInteger.BIN only

1,4,5,7 ON

3,6,8 OFF

2 - Toggle Between FP/INTEGER BASIC (Apple II)

When dips are set this way, the system ROMS are entirely on the Brain Board (this is done by inverting switches 3/4 from the previous settings). This means that you should be able to run an Apple II logic board with no onboard ROMs.

In this mode, the back toggle will still enable Wozaniam (Apple 1 mode) when up, but when flipped down, it will boot either Applesoft or Integer BASIC from the Brainboard's ROM depending on the position of DIP2. DIP2 was unused in the original Brainboard design/documentation. SETTING 1 is most compatible with other expansion cards and accessories, since it uses the system rom when the main switch is disabled. The second config makes the brain board more versatile by accessing the other slots of the ROM, but it may cause conflict with some expansion cards.

# ROM Layout

Split files of the ROM are provided if you wish to arrange your own rom, but both .BIN files are also ready to burn, so you don't have to do this part.

ApplesoftInteger.bin splits in order to this combination:
xaa-wozaniam
xab-applesoft
xac-wozaniam
xad-integer

DIP2 always selects the top or bottom half of this whole stack (i.e. xaa and xab, or xac and xad become the low and high bank to the brain board). 

The main toggle switch on the card then enables the low bank of the half of the ROM currently in use (i.e. xaa if xaa and xab are in use / usually wozaniam, alternately integer BASIC if you use QuickStart.bin and toggle DIP2). 

Turning the switch off re-enables the Apple II's onboard ROM, or, an applesoft/integer bank if SETTING 2 is in use. 

Layout of the QuickStart.bin file is the result of this command to rearrange the parts:
`cat xad-integer xaa-wozaniam xac-wozaniam xab-applesoft > QuickStart.bin` 

This command is placing integer basic in the lower half of one DIP2 bank, and wozaniam in the lower half of the other, essentially making this both an Integer BASIC rom card and Apple 1 emulation card using the SETTING 1 Dips. As noted above when using this ROM and SETTING 1, DIP2 changes between these choices of Integer Basic and Wozaniam.

# GETTING A CARD:
Sometimes I have completed cards on my eBay store, and bare PCB's are always available there:
https://www.ebay.com/str/arcadealex

I can also be contacted via AppleFritter Forums or VCF for a DIY kit, username skate323k137.

# MAKING IT YOURSELF (Without a kit and/or PCB from me):

**The 'Forum Pack' directory has everything you need to get a card manufactured, and to program your ROM presuming you have an EPROM programmer. A TL-866 or TOP-3000 etc is sufficient. Within that directory you will find:**

**Beta_4_gerbers.zip** - Can be uploaded directy to PCBWAY to get your own PCBs fabricated. Use their option to bevel the edge connectors, and if they ask you if they can trim a little length from the edge fingers that is fine. Alternately I have uploaded the project to their site, and I receive a small commission if you want to purchase unpopulated PCB's via this link: https://www.pcbway.com/project/shareproject/Brain_Board_][_For_Apple_II_computers_d632392b.html

**BrainBoard_512_Beta_4.zip** - Osmond Project (Free PCB editor software), can be opened in the program OSMOND and modified. Delete AUX2 layer after you export Gerbers, AUX1 is board outline. 

**ApplesoftInteger.BIN** - Burn to a 27C512 or SST 27SF512 ROM. Contains the ROM necessary for both of the above configurations (SETTING 1, SETTING 2).

**QuickStart.BIN** - Burn to a 27C512 or SST 27SF512 ROM. Contains the ROM necessary for using Integer and Wozaniam (DIP2) while retaining the system ROM. (SETTING 1 ONLY).

**rom-split directory** - an ordered split of ApplesoftInteger.BIN as noted above in ROM LAYOUT.

Other files found in this repository are copies of Mikes original code/design to keep it together under GPL, and the original photos/documentation of the ROM mod by Macnoyd from which this hardware revision was derived. 

# PARTS LIST

<img width="759" alt="Parts List" src="https://user-images.githubusercontent.com/20172602/217967094-c93ea15a-7407-4f5b-b446-b7429ac69a04.png">


