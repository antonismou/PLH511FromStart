interface PacketQueue
{
	command bool empty();
	command bool full();
	command uint8_t size();
	command uint8_t maxSize();
	command message_t head();
	command error_t dequeue(message_t* out);
	command error_t enqueue(message_t newVal);
	command message_t element ( uint8_t mindex);
}
