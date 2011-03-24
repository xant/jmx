/*
 *  JMXGlobals.h
 *  JMX
 *
 *  Created by xant on 2/18/11.
 *  Copyright 2011 Dyne.org. All rights reserved.
 *
 */

// Generic syslog based logging
#include <syslog.h>

#define LOG_DEBUG2              (LOG_DEBUG+1)
#define LOG_DEBUG3              (LOG_DEBUG+2)
#define LOG_DEBUG4              (LOG_DEBUG+3)

#define ERROR(fmt,args...)      do { if (verbose >= LOG_ERR)     syslog(LOG_ERR,     "E: " fmt, ## args); } while (0)
#define WARNING(fmt,args...)    do { if (verbose >= LOG_WARNING) syslog(LOG_WARNING, "W: " fmt, ## args); } while (0)
#define NOTICE(fmt,args...)     do { if (verbose >= LOG_NOTICE)  syslog(LOG_NOTICE,  "N: " fmt, ## args); } while (0)
#define INFO(fmt,args...)       do { if (verbose >= LOG_INFO)    syslog(LOG_INFO,    "I: " fmt, ## args); } while (0)
#define DEBUG(fmt,args...)      do { if (verbose >= LOG_DEBUG)   syslog(LOG_DEBUG,   "D:%s:%d " fmt, __FUNCTION__, __LINE__, ## args); } while (0)
#define DEBUG2(fmt,args...)     do { if (verbose >= LOG_DEBUG2)  syslog(LOG_DEBUG,   "D2:%s:%d " fmt, __FUNCTION__, __LINE__, ## args); } while (0)
#define DEBUG3(fmt,args...)     do { if (verbose >= LOG_DEBUG3)  syslog(LOG_DEBUG,   "D3:%s:%d " fmt, __FUNCTION__, __LINE__, ## args); } while (0)
// Two versions that increase (decrement) and decrease (increment) the priority
#define DEBDEC(n,fmt,args...)   do { if (verbose >= LOG_DEBUG-(n)) syslog(LOG_DEBUG-(n), "V%d:%s:%d " fmt, 1-n, __FUNCTION__, __LINE__, ## args); } while (0)
#define DEBINC(n,fmt,args...)   do { if (verbose >= LOG_DEBUG+(n)) syslog(LOG_DEBUG+(n), "V%d:%s:%d " fmt, 1+n, __FUNCTION__, __LINE__, ## args); } while (0)
// Syslog is too slow for this level
//#define DPRINTF(fmt,args...)    do { if (verbose >= LOG_DEBUG4)  fprintf(stderr, fmt "\n", ## args); } while (0)

#define VERBOSE_DEFAULT         LOG_WARNING     //!< \brief default verbose level (syslog LOG_* value)

extern int verbose;