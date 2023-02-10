# Brain-Board-II
Updated "Brain Board" originally designed by Mike Willegal

![s-l500](https://user-images.githubusercontent.com/20172602/217665056-29c14f80-c498-4fa3-8919-e9a7e37e5e0b.jpeg)

The Brain Board II is a slot card for the Apple II, II+, and IIe computers. It allows use of the Wozaniam pack to mimic Apple-1 Operation (including Cassette interface), as well as provides a user ROM area which can be used to boot Integer BASIC among other possibilities. 

The original documentation for the card can be found on Mike Willegal's site: http://www.willegal.net/appleii/brainboard.htm

The BOM on page BB:3 should be appended from the original design as follows:

Include one more 10K resistor. (5 in total)

The 6 non-polarized capacitors shown on this page should be .1uf, not .01uf. 

Lastly, it is imperative to use a 27C512 or SST 27SF512 with this design in place of the 27c256 EPROM.


Normal operation is the same if you follow the quick start guide from the original Brain Board manual. bb-v5_1.pdf is provided in this repository, but for convenience, these are the 2 most common settings. 

# SETTING 1: QUICK START

DIPS:
1,3,5,8: ON

4,6,7 OFF

In this mode, the back toggle will switch between normal system ROM, and the Wozaniam (apple 1 emulation) mode.

The updated design to take advantage of this Brain Board II modification uses the following configuration:

# SETTING 2: APPLESOFT / INTEGER BASIC

1,4,5,7 ON

3,5,6 OFF
2 - FP/INTEGER

In this mode, the back toggle will still enable Wozaniam when up, but when flipped down, it will boot either Applesoft or Integer BASIC from the Brainboard's ROM depending on the position of DIP2. DIP2 was unused in the original Brainboard design/documentation. If you do not need Apple II Integer basic, the first config is most compatible with other expansion cards and accessories. The second config makes the brain board more versatile but may cause conflict with some expansion cards.

# GETTING A CARD:
Sometimes I have completed cards on my eBay store:
https://www.ebay.com/str/arcadealex

I can also be contacted via AppleFritter Forums or VCF for a DIY kit, username skate323k137.

# MAKING IT YOURSELF (Without a kit from me):

**The 'Forum Pack' directory has everything you need to get a card manufactured, and to program your ROM presuming you have an EPROM programmer. A TL-866 or TOP-3000 etc is sufficient. Within that directory you will find:**

**Beta_4_gerbers.zip** - Can be uploaded directy to PCBWAY to get your own PCBs fabricated. Use their option to bevel the edge connectors, and if they ask you if they can trim a little length from the edge fingers that is fine. Alternately I have uploaded the project to their site, and I receive a small commission if you want to purchase unpopulated PCB's via this link: https://www.pcbway.com/project/shareproject/Brain_Board_][_For_Apple_II_computers_d632392b.html

**BrainBoard_512_Beta_4.zip** - Osmond Project (Free PCB editor software), can be opened in the program OSMOND and modified. Delete AUX2 layer after you export Gerbers, AUX1 is board outline. 

**CO.512.SuperBrain_Board AppleSoftInteger.BIN** - Burn to a 27C512 or SST 27SF512 ROM. Contains the ROM necessary for both of the above configurations (SETTING 1, SETTING 2).

Other files found in this repository are copies of Mikes original code/design to keep it together under GPL, and the original photos/documentation of the ROM mod by Macnoyd from which this hardware revision was derived. 
