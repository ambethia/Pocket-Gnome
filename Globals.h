// This file no longer matters.
// We stopped using the external memory reading tool after it became clear
// that it was way too slow to serve any purpose.

#define MEMORY_GOD_MODE 1

#define USE_ITEM_MASK       0x80000000
#define USE_MACRO_MASK      0x40000000

#define APPLICATION_SUPPORT_FOLDER	@"~/Library/Application Support/PocketGnome/"
#define PLUGIN_FOLDER				[NSString stringWithFormat:@"%@plugins", APPLICATION_SUPPORT_FOLDER]