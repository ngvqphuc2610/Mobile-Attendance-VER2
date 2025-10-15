// CommonJS export
module.exports = function socketHandler(io) {
  io.on('connection', (socket) => {
    console.log('🟢 Socket connected:', socket.id);

    socket.on('check_in', (data) => {
      // Broadcast tới tất cả client
      io.emit('attendance_update', { ...data, time: new Date() });
    });

    socket.on('disconnect', () => console.log('🔴 Disconnected:', socket.id));
  });
};
