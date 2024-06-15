import 'package:flutter/material.dart';

class GroupMessageCard extends StatefulWidget {
  final String message;
  final String sender;
  final bool isSendByMe;
  const GroupMessageCard(
      {super.key,
      required this.message,
      required this.sender,
      required this.isSendByMe});

  @override
  State<GroupMessageCard> createState() => _GroupMessageCardState();
}

class _GroupMessageCardState extends State<GroupMessageCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: widget.isSendByMe ? 0 : 24,
          right: widget.isSendByMe ? 24 : 0),
      alignment:
          widget.isSendByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: widget.isSendByMe
            ? const EdgeInsets.only(left: 30)
            : const EdgeInsets.only(right: 30),
        padding: const EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
        
        decoration: BoxDecoration(
            borderRadius: widget.isSendByMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20))
                : const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
            color: widget.isSendByMe
                ? const Color.fromARGB(255, 161, 226, 236)
                : const Color.fromARGB(255, 190, 219, 233)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sender.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
