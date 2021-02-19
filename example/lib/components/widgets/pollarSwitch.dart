import 'package:flutter/material.dart';

import '../../util/colorProvider.dart';
import '../../util/inner_shadow.dart';

///Toggle switch that maintians neumorphic pollar design
class PollarToggleSwitch extends StatefulWidget {

  ///The toggle value
  final bool active;

  ///The on toggle function
  final Function(bool) onToggle;

  const PollarToggleSwitch({Key key, this.active = true, this.onToggle}) : super(key: key);

  @override
  _PollarToggleSwitchState createState() => _PollarToggleSwitchState();
}

class _PollarToggleSwitchState extends State<PollarToggleSwitch> {

  ///The button toggle value
  bool active;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      active = widget.active;
    });
  }

  @override
  Widget build(BuildContext context) {

    ///General app styles
    final appColors = ColorProvider.of(context);

    return GestureDetector(
      //Call the toggle callback
      onTap: () {
        setState(() {
          active = !active;
        });
        widget.onToggle(active);
      },
      onPanUpdate: (det){
        setState(() {
          if(det.delta.dx < 0 && active){
            active = false;
            widget.onToggle(active);
          }
          if(det.delta.dx > 0 && !active){
            active = true;
            widget.onToggle(active);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36.5),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.25),
              Color(0xFF3F5E7E).withOpacity(0.10)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
          )
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36.5),
              color: appColors.surface
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Stack(
                children: [

                  //Bakcground
                  InnerShadow(
                    offset: Offset(3, 3),
                    blur: 7,
                    color: !active ? Color(0xFFB6C8D8).withOpacity(0.48) : Colors.transparent,
                    child: InnerShadow(
                      offset: Offset(-3, -3),
                      blur: 7,
                      color: active? Colors.transparent : Colors.white,
                      child: AnimatedContainer(
                        width: 52,
                        height: 32,
                        duration: Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: active ? appColors.blue : appColors.surface,
                          borderRadius: BorderRadius.circular(36.5)
                        ),
                      ),
                    ),
                  ),

                  //Notch
                  Positioned(
                    top: 2,
                    bottom: 2,
                    right: 2,
                    left: 2,
                    child: AnimatedAlign(
                      alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                      duration: Duration(milliseconds: 200),
                      child: InnerShadow(
                        color: Colors.white,
                        offset: Offset(1, 1),
                        blur: 1,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: appColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Color(0xFF92ACC4).withOpacity(0.14), offset: Offset(1, 1), blurRadius: 1),
                              BoxShadow(color: Color(0xFF92ACC4).withOpacity(0.12), offset: Offset(2, 2), blurRadius: 1, spreadRadius: -1),
                              BoxShadow(color: Color(0xFF92ACC4).withOpacity(0.20), offset: Offset(1, 1), blurRadius: 3),
                            ]
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}