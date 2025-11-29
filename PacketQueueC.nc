
#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif

generic module PacketQueueC( uint8_t queueSize)
{
	provides interface PacketQueue;
}
implementation
{
	message_t Q[queueSize];
	uint8_t headIndex=0;
	uint8_t tailIndex=0;
	uint8_t size=0;
	
	//bool isEmpty=TRUE;
	//bool isFull=FALSE;
	
	command bool PacketQueue.empty()
	{
		bool em;
		atomic{
		em = (size==0);}
		
		return em;
	}
	
	command bool PacketQueue.full()
	{
		bool em;
		atomic{
		if (size==queueSize)
		{
			em=TRUE;
		}
		else
		{
			em=FALSE;
		}
		}
		return em ;
	}
	command uint8_t PacketQueue.size()
	{
		uint8_t ms;
		
		atomic{
			ms= size;
		}
		return ms;
	}
	
	command uint8_t PacketQueue.maxSize()
	{
		uint8_t ms;
		
		atomic{
			ms= queueSize;
		}
		return ms;
	}
	
	/**
	 * @deprecated
	 */
	command message_t PacketQueue.head()
	{	
		if (headIndex >= queueSize) {
			dbg("PacketQueueC","head(): CRITICAL - headIndex %u >= queueSize %u\n", headIndex, queueSize);
			message_t m;
			memset(&m, 0, sizeof(message_t));
			return m;
		}
		return Q[headIndex];
	}
	
	
	
	command error_t PacketQueue.enqueue(message_t newPkt)
	{
		bool wasEmpty=FALSE, isFull=FALSE;
		
		atomic{
		wasEmpty= (size==0);//call PacketQueue.empty();
		isFull=(size==queueSize);
		}
		
		if (isFull)
		{
			dbg("PacketQueueC","enqueue(): Queue is FULL!!! Size: %u/%u\n", size, queueSize);
#ifdef PRINTFDBG_MODE
			printf("PacketQueueC:enqueue(): Queue is FULL!!!\n");
			printfflush();
#endif
			return FAIL;
		}
				
		atomic{
			if(!wasEmpty)
			{
				tailIndex = (tailIndex+1)%queueSize;
			}
			// Safety check: ensure tailIndex is within bounds
			if (tailIndex >= queueSize) {
				dbg("PacketQueueC","enqueue(): CRITICAL - tailIndex %u >= queueSize %u\n", tailIndex, queueSize);
				tailIndex = 0;
			}
			memcpy(&Q[tailIndex],&newPkt,sizeof(message_t));
			size++;
		}
		dbg("PacketQueueC","enqueue(): Enqueued in pos= %u, Queue size NOW: %u/%u\n",tailIndex, size, queueSize);
#ifdef PRINTFDBG_MODE
		printf("PacketQueueC : enqueue() : pos=%u \n", tailIndex);
		printfflush();
#endif
		return SUCCESS;
	}
	
	command message_t PacketQueue.dequeue()
	{
		uint8_t tmp;
		bool isEmpty=FALSE;
		message_t  m;
		atomic{
			isEmpty=(size==0);
		}
		if (isEmpty)
		{
			dbg("PacketQueueC","dequeue(): Q is empty!!!! Size: %u\n", size);
#ifdef PRINTFDBG_MODE
			printf("PacketQueueC : dequeue() : Q is empty!!! \n");
			printfflush();
#endif
			atomic{
				memset(&m, 0, sizeof(message_t));
			}
			return m;
		}
		
		
		atomic{
			tmp=headIndex;
			// Safety check: ensure headIndex is within bounds
			if (headIndex >= queueSize) {
				dbg("PacketQueueC","dequeue(): CRITICAL - headIndex %u >= queueSize %u\n", headIndex, queueSize);
				headIndex = 0;
				tmp = 0;
			}
			if(tailIndex!=headIndex)
			{
				headIndex=(headIndex+1)%queueSize;
			}
			size--;
			m=Q[tmp];
		}
		dbg("PacketQueueC","dequeue(): Dequeued from pos = %u, Queue size NOW: %u/%u\n",tmp, size, queueSize);
#ifdef PRINTFDBG_MODE
		printf("PacketQueueC : dequeue(): pos = %u \n", tmp);
		printfflush();
#endif
		return m;
	}
	
	command message_t PacketQueue.element(uint8_t mindex)
	{
		message_t m;
		if (mindex >= queueSize) {
			dbg("PacketQueueC","element(): index %u out of bounds (max %u)\n", mindex, queueSize-1);
			atomic{ memset(&m, 0, sizeof(message_t)); }
			return m;
		}
		atomic{
			m = Q[mindex];
		}
		return m;
	}	
}
