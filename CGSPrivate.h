/* CGSPrivate.h -- Header file for undocumented CoreGraphics stuff. */

#include <Carbon/Carbon.h>

/* These functions all return a status code. Typical CoreGraphics replies are:
kCGErrorSuccess = 0,
kCGErrorFirst = 1000,
kCGErrorFailure = kCGErrorFirst,
kCGErrorIllegalArgument = 1001,
kCGErrorInvalidConnection = 1002,
*/

// Internal CoreGraphics typedefs
typedef int		CGSConnection;
typedef int		CGSWindow;
typedef int		CGSValue;
typedef int		CGSWindowID;
//typedef void	*CGSConnectionID;

//// CONSTANTS ////

/* Window ordering mode. */
typedef enum _CGSWindowOrderingMode {
    kCGSOrderAbove                =  1, // Window is ordered above target.
    kCGSOrderBelow                = -1, // Window is ordered below target.
    kCGSOrderOut                  =  0  // Window is removed from the on-screen window list.
} CGSWindowOrderingMode;

// Internal CoreGraphics functions.

/* Retrieve the workspace number associated with the workspace currently
 * being shown.
 *
 * cid -- Current connection.
 * workspace -- Pointer to int value to be set to workspace number.
 */
extern OSStatus CGSGetWorkspace(const CGSConnection cid, int *workspace);

/* Retrieve workspace number associated with the workspace a particular window
 * resides on.
 *
 * cid -- Current connection.
 * wid -- Window number of window to examine.
 * workspace -- Pointer to int value to be set to workspace number.
 */
extern OSStatus CGSGetWindowWorkspace(const CGSConnection cid, const CGSWindow wid, int *workspace);

/* Show workspace associated with a workspace number.
 *
 * cid -- Current connection.
 * workspace -- Workspace number.
 */
extern OSStatus CGSSetWorkspace(const CGSConnection cid, int workspace);

// Transitions we can apply
typedef enum {
	CGSNone = 0,			// No transition effect.
	CGSFade,				// Cross-fade.
	CGSZoom,				// Zoom/fade towards us.
	CGSReveal,				// Reveal new desktop under old.
	CGSSlide,				// Slide old out and new in.
	CGSWarpFade,			// Warp old and fade out revealing new.
	CGSSwap,				// Swap desktops over graphically.
	CGSCube,				// The well-known cube effect.
	CGSWarpSwitch,			// Warp old, switch and un-warp.
	CGSFlip					// Flip over
} CGSTransitionType;

// All our transition styles - passed under "option" when invoking
// Mostly just directions
// Transparent Mask "(1<<7)" goes with option if applied.
typedef enum {
	CGSDown,			// Old desktop moves down.
	CGSLeft,			// Old desktop moves left.
	CGSRight,			// Old desktop moves right.
	CGSInRight,			// CGSSwap: Old desktop moves into screen,
						// new comes from right.
	CGSBottomLeft = 5,	// CGSSwap: Old desktop moves to bottom-left,
						// new comes from top-right.
	CGSBottomRight,		// Old desktop to br, New from tl.
	CGSDownTopRight,	// CGSSwap: Old desktop moves down, new from tr.
	CGSUp,				// Old desktop moves up.
	CGSTopLeft,			// Old desktop moves tl.
	CGSTopRight,		// CGSSwap: old to tr. new from bl.
	CGSUpBottomRight,	// CGSSwap: old desktop up, new from br.
	CGSInBottom,		// CGSSwap: old in, new from bottom.
	CGSLeftBottomRight,	// CGSSwap: old one moves left, new from br.
	CGSRightBottomLeft,	// CGSSwap: old one moves right, new from bl.
	CGSInBottomRight,	// CGSSwap: onl one in, new from br.
	CGSInOut			// CGSSwap: old in, new out.
} CGSTransitionOption;

typedef struct CGPointWarp {
        CGPoint local;
        CGPoint global;
}CGPointWarp;

/* Get the default connection for the current process. */
extern CGSConnection _CGSDefaultConnection(void);

// Behaviour of window during expose / regarding workspaces
typedef enum {
	CGSTagNone					= 0,		// No tags
	CGSTagExposeFade		= 0x0002,		// Fade out when Expose activates.
	CGSTagNoShadow			= 0x0008,		// No window shadow.
	CGSTagTransparent   = 0x0200,   		// Transparent to mouse clicks.
	CGSTagSticky				= 0x0800,	// Appears on all workspaces.
} CGSWindowTag;

extern OSStatus CGSSetWorkspaceWithTransition(const CGSConnection cid,
        int workspaceNumber, CGSTransitionType transition, CGSTransitionOption subtype, 
        float time);

typedef struct {
	uint32_t unknown1;
	CGSTransitionType type;
	CGSTransitionOption option;
	CGSWindow wid;			/* Can be 0 for full-screen */
	float *backColour;	/* Null for black otherwise pointer to 3 float array with RGB value */
} CGSTransitionSpec;

/* Transition handling. */
extern OSStatus CGSNewTransition(const CGSConnection cid, const CGSTransitionSpec* spec, int *pTransitionHandle);
extern OSStatus CGSInvokeTransition(const CGSConnection cid, int transitionHandle, float duration);
extern OSStatus CGSReleaseTransition(const CGSConnection cid, int transitionHandle);

// window warping
extern CGError CGSSetWindowWarp(const CGSConnection cid, const CGSWindow wid, int w, int h, CGPointWarp mesh[w][h]);

// thirtyTwo must = 32 for some reason. tags is pointer to 
//array ot ints (size 2?). First entry holds window tags.
// 0x0800 is sticky bit.
extern OSStatus CGSGetWindowTags(const CGSConnection cid, const CGSWindow wid, CGSWindowTag *tags, int thirtyTwo);
extern OSStatus CGSSetWindowTags(const CGSConnection cid, const CGSWindow wid, CGSWindowTag *tags, int thirtyTwo);
extern OSStatus CGSClearWindowTags(const CGSConnection cid, const CGSWindow wid, CGSWindowTag *tags, int thirtyTwo);
extern OSStatus CGSGetWindowEventMask(const CGSConnection cid, const CGSWindow wid, uint32_t *mask);
extern OSStatus CGSSetWindowEventMask(const CGSConnection cid, const CGSWindow wid, uint32_t mask);

// Gets the screen rect for a window.
extern OSStatus CGSGetScreenRectForWindow(const CGSConnection cid, CGSWindow wid, CGRect *outRect);
extern OSStatus CGSGetWindowBounds(const CGSConnection cid, const CGSWindow wid, CGRect *ret);

// some other window functions
//extern int CGSCaptureWindowsContentsToRect(const CGSConnection cid, CGRect rect, const CGSWindow wid, int zero); /* i made this line up, its totally wrong */
extern void CGContextCopyWindowCaptureContentsToRect(void *grafport, CGRect rect, const CGSConnection cid, const CGSWindow wid, int zero);
extern OSStatus CGSFindWindowByGeometry(const CGSConnection cid, int zero, int one, int zero_again, CGPoint *screen_point, CGPoint *window_coords_out, CGSWindow *wid_out, CGSConnection *cid_out);

// Window appearance/position
extern OSStatus CGSSetWindowAlpha(const CGSConnection cid, const CGSWindow wid, float alpha);
extern OSStatus CGSSetWindowListAlpha(const CGSConnection cid, CGSWindow *wids, int count, float alpha);
extern OSStatus CGSGetWindowAlpha(const CGSConnection cid, const CGSWindow wid, float* alpha);
extern OSStatus CGSMoveWindow(const CGSConnection cid, const CGSWindow wid, CGPoint *point);
extern OSStatus CGSSetWindowTransform(const CGSConnection cid, const CGSWindow wid, CGAffineTransform transform); 
extern OSStatus CGSGetWindowTransform(const CGSConnection cid, const CGSWindow wid, CGAffineTransform * outTransform); 
extern OSStatus CGSSetWindowTransforms(const CGSConnection cid, CGSWindow *wids, CGAffineTransform *transform, int n); 

// gets connectionID for given process serial number
extern CGError CGSGetConnectionIDForPSN(UInt32 inParam1, ProcessSerialNumber* inPSN, CGSConnection* outConnectionID);

// Get on-screen window counts and lists.
extern OSStatus CGSGetWindowCount(const CGSConnection cid, CGSConnection targetCID, int* outCount); 
extern OSStatus CGSGetWindowList(const CGSConnection cid, CGSConnection targetCID, int listSize, int* list, int* numberOfWindows);

// Get on-screen window counts and lists.
extern OSStatus CGSGetOnScreenWindowCount(const CGSConnection cid, CGSConnection targetCID, int* outCount); 
extern OSStatus CGSGetOnScreenWindowList(const CGSConnection cid, CGSConnection targetCID, int count, int* list, int* outCount);

// Per-workspace window counts and lists.
extern OSStatus CGSGetWorkspaceWindowCount(const CGSConnection cid, int workspaceNumber, int *outCount);
extern OSStatus CGSGetWorkspaceWindowList(const CGSConnection cid, int workspaceNumber, int count, 
    int* list, int* outCount);

// Gets the level of a window
extern OSStatus CGSGetWindowLevel(const CGSConnection cid, CGSWindow wid, int *level);

// Window ordering
extern OSStatus CGSOrderWindow(const CGSConnection cid, const CGSWindow wid, CGSWindowOrderingMode place, CGSWindow relativeToWindowID /* can be NULL */);   

extern OSStatus CGSMoveWorkspaceWindows(const CGSConnection connection, int toWorkspace, int fromWorkspace);
extern OSStatus CGSMoveWorkspaceWindowList(const CGSConnection connection, CGSWindow *wids, int count, 
        int toWorkspace);

extern OSStatus CGSGetWindowProperty(const CGSConnection cid, CGSWindow wid, CGSValue key,
        CGSValue *outValue);
		
extern OSStatus CGSUncoverWindow(const CGSConnection cid, const CGSWindow wid);
extern OSStatus CGSFlushWindow(const CGSConnection cid, const CGSWindow wid, int unknown /* 0 works */ );

extern OSStatus CGSGetWindowOwner(const CGSConnection cid, const CGSWindow wid, CGSConnection *ownerCid);
extern OSStatus CGSConnectionGetPID(const CGSConnection cid, pid_t *pid, const CGSConnection ownerCid);

// Values
//extern CGSValue CGSCreateCStringNoCopy(const char *str);    // gone in leopard
extern char* CGSCStringValue(CGSValue string);
extern int CGSIntegerValue(CGSValue intVal);
extern void *CGSReleaseGenericObj(CGSValue value); /* was void* */