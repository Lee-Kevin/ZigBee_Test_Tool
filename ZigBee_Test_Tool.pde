/** 
* ZigBee-Test Tool
* This is a tool used for test zigbee
 */

 
import processing.serial.*;
import controlP5.*;
import java.util.*;
import java.util.Formatter;
import g4p_controls.*;
import java.io.*;


public static final int DEVICE_ID_S01 = 0x07;
public static final int DEVICE_ID_S02 = 0x05;
public static final int DEVICE_ID_S03 = 0x14;
public static final int DEVICE_ID_S04 = 0x01;
public static final int DEVICE_ID_S05 = 0x08;
public static final int DEVICE_ID_S06 = 0xD0;
public static final int DEVICE_ID_S07 = 0x03;
public static final int DEVICE_ID_S08 = 0x18;
public static final int DEVICE_ID_S09 = 0xD1;
public static final int DEVICE_ID_S10 = 0xC0;
public static final int DEVICE_ID_S11 = 0xC1;
public static final int DEVICE_ID_S12 = 0xC2;
public static final int DEVICE_ID_S13 = 0xC3;

int now_length = 0;
int last_length = 0;

PImage bg;  
GImageButton btnAllowNet, btnForbitNet,btnResetNet,btnTestAll;
// Components


Serial myPort;// The serial port
public static ControlP5 cp5;
DropdownList COM_List;
ZigBeeDev Device;
Console_Class my_console;
Println console;
int[] serialInArray = new int[50];    // Where we'll put what we receive
int serialCount = 0;                 // A count of how many bytes we receive
int xpos, ypos;                 // Starting position of the ball
boolean firstContact = false;        // Whether we've heard from the microcontroller
boolean Data_Recived_Flag = false;
boolean UpdateDrawFlag        = false;
boolean ClearDrawFlag         = false;
boolean InitDone              = false;

JSONArray [] grove_files = new JSONArray[4];
JSONObject json;

color led_color;
Textlabel DeviceName_Textlabel;
Textlabel DeviceID_Textlabel;
Textlabel Opteration_Textlabel;
Textlabel NetStatus_Textlabel;


void setup() {
    size(1024, 560);  // Stage size
    //noStroke();      // No border on the next thing drawn
    cp5 = new ControlP5(this);
    bg = loadImage("background.jpg"); /* 背景图 */
	Device = new ZigBeeDev(cp5);
    
    
    String[] files;
    
    files = new String[] {
        "allownet_0.png","allownet_1.png","allownet_2.png"
    };
    btnAllowNet = new GImageButton(this,104,1, files);
    
    files = new String[] {
        "forbidnet_0.png","forbidnet_1.png","forbidnet_2.png"
    };
    btnForbitNet = new GImageButton(this,233,1, files);

    files = new String[] {
        "resetnet_0.png","resetnet_1.png","resetnet_2.png"
    };
  btnResetNet = new GImageButton(this,362,1, files);
    files = new String[] {
        "testall_0.png","testall_1.png","testall_2.png"
    };
  btnTestAll = new GImageButton(this,491,1, files);
 
 
  DeviceName_Textlabel = cp5.addTextlabel("label1")
                    .setText("Device Name")
                    .setPosition(110,70)
                    .setColorValue(0xffffff00)
                    .setFont(createFont("Georgia",20))
                    ;
  DeviceID_Textlabel = cp5.addTextlabel("label2")
                    .setText("Device ID")
                    .setPosition(450,70)
                    .setColorValue(0xffffff00)
                    .setFont(createFont("Georgia",20))
                    ;
  Opteration_Textlabel = cp5.addTextlabel("label3")
                    .setText("   TEST  ")
                    .setPosition(720,70)
                    .setColorValue(0xffffff00)
                    .setFont(createFont("Georgia",20))
                    ;
  NetStatus_Textlabel = cp5.addTextlabel("label4")
                    .setText("Net Status")
                    .setPosition(610,8)
                    .setColorValue(0xff000000)
                    .setFont(createFont("Georgia",20))
                    ;
  COM_List = cp5.addDropdownList("SELECT PORT")
                .setPosition(1, 1)
                .setFont(createFont("arial black", 11))
                .setSize(100, 140)
                ;
	my_console = new Console_Class(console,cp5);
	my_console.init();
  
    // Device.init(cp5);
	led_color = color(255,255,0);
}


void draw() {

    image(bg,0,0,1024,560);  
	fill(led_color);
	ellipse(730,22,25,25);
	scan_serial_ports();
    noStroke();
	Device.draw();
	
}

// 设备相关的操作函数

public class Console_Class {
	int[] __init_coor = new int[2];
	Println _console;
	ControlP5 _cp5;
	Textarea myTextarea;
	Console_Class(Println console,ControlP5 cp5) {
		_console = console;
		_cp5     = cp5;
		__init_coor[0] = 100;
		__init_coor[1] = 480;
		
	}
	void init() {
	    myTextarea = _cp5.addTextarea("txt")
					    .setPosition(__init_coor[0], __init_coor[1])
					    .setSize(824, 75)
					    .setFont(createFont("arial", 14))
					    .setLineHeight(14)
				  	    .setColor(color(200))
					    .setColorBackground(color(0,0,0))
					    .setColorForeground(color(255,255,255));
		_console = _cp5.addConsole(myTextarea);//
	}
	
}



public class ZigBeeDev{
    int[] __init_coor = new int[2];
    Hashtable devinfo = new Hashtable();
	public ControlP5 _cp5;
	Textlabel[] dev_textlabel = new Textlabel[20];
	Textlabel[] devid_textlabel = new Textlabel[20];
	Textlabel[] test_result_textlabel = new Textlabel[20];
	
    int DevItems = 0;
    color[] __colorGroup = new color[2];
    ZigBeeDev(ControlP5 cp5) {

        initDev(cp5);
    }
    
    void initDev(ControlP5 cp5) {
        __init_coor[0] = 0;
        __init_coor[1] = 40;
		_cp5 = cp5;
    }
    
    void draw() {
		fill(90);
        rect(100,70,824,400);
		if (UpdateDrawFlag == true) {
			fill(90);
			rect(100,70,824,400);
			UpdateDrawFlag = false;
			Enumeration devname;
			devname = devinfo.keys();


			int i = 0;
			int idevid = 0;
			while(devname.hasMoreElements()) {
			String str;
			String str_id;
			String label_devid = "";
			String label_name = "";
			String button_name = "";
			String label_result = "";
			  str = (String) devname.nextElement();
			  label_name = "dev_name" + Integer.toHexString(i);
			  dev_textlabel[i] = _cp5.addTextlabel(label_name)
								.setText(str)
								.setPosition(125,90+i*20)
								.setColorValue(0xffffffff)
								.setFont(createFont("Arial",15))
								;
			  str_id = (String) devinfo.get(str);
			  label_devid = "dev_id" + Integer.toHexString(i); 			
			  devid_textlabel[i] = _cp5.addTextlabel(label_devid)
								.setText(str_id)
								.setPosition(425,90+i*20)
								.setColorValue(0xffffffff)
								.setFont(createFont("Arial",15))
								;
			button_name = "button_" + Integer.toHexString(i);
			label_result = "label_result_" + Integer.toHexString(i);
			
			idevid= (int) (0xff & Integer.parseInt(str_id.substring(0, 2),16));
			if (idevid < 0xC0) {
				
				try {
					_cp5.getController(button_name).remove();
				} catch (Exception e) {
					
				}
				test_result_textlabel[i] = _cp5.addTextlabel(label_result)
								.setText("TEST OK")
								.setPosition(720,90+i*20)
								.setColorValue(0xffffffff)
								.setFont(createFont("Arial",15))
								;
								
								
			} else {
				try {
					_cp5.getController(label_result).remove();
				} catch (Exception e) {
					
				}
				_cp5.addButton(button_name)
					 .setLabel("test") 
					 .setId(0)
					 .setValue(i)
					 .setPosition(700,90+i*20)
					 .setSize(130,18)
					 .setFont(createFont("Georgia",18))
					 ;
			}

			
			i++;
			}
		}
		if (ClearDrawFlag) {
		} 
    }
    void createItems(String devname,String devId) {
        devinfo.put(devname,devId);
    }
//  如果无该设备，返回0，已经有该设备返回1
	int ifrepeat(String devname) {         
		if(devinfo.get(devname) == null) {
			return 0;
		} else {
			return 1;
		}
	}
	void printItems() {
		Enumeration devname;
		devname = devinfo.keys();
		String str;
		while(devname.hasMoreElements()) {
         str = (String) devname.nextElement();
         System.out.println(str + ": " +
         devinfo.get(str));
		}
	}
	void clearDisplay() {
		ClearDrawFlag = true;
		Enumeration devname;
		devname = devinfo.keys();
        String label_devid = "";
        String label_name = "";
        String label_result = "";
		String button_name = "";
		int i = 0;
		String str;
		while(devname.hasMoreElements()) {
			str = (String) devname.nextElement();
					 System.out.println(str + ": " +
					 devinfo.get(str));
			i++;
		}
		println("i: "+i);
		devinfo.clear();
		
		for (int j=0; j<i;j++) {
			label_name = "dev_name" + Integer.toHexString(j);
			label_devid = "dev_id" + Integer.toHexString(j);  
			label_result = "label_result_" + Integer.toHexString(j);  
			button_name = "button_" + Integer.toHexString(j);
			_cp5.getController(label_name).remove();
			_cp5.getController(label_devid).remove();
			try {
				_cp5.getController(button_name).remove();
			} catch (Exception e) {
				
			}
			try {
				_cp5.getController(label_result).remove();
			} catch (Exception e) {
				
			}
			
		}
	}
	
	void clearItems() {
	}
	
//  如果无该设备，返回0，已经有该设备返回1
	int deleteItems(String devname) {         
		devinfo.remove(devname);
		return 1;
	}
	// 发送翻转指令
	public void sendTestCMD(int index) {
		int[] data = new int[11];                                  //fuzai
		int[] inByte = {0x55, 0x3A, 0x20, 0x00, 0x01, 0x00, 0x02, 0x00, 0x20, 0x01, 
						0xF0,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
						0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEC};
		int _index = 0;
		Enumeration devname;
		devname = devinfo.keys();
		String str;
		String dev_info = "";
		while(devname.hasMoreElements()) {
			str = (String) devname.nextElement();
			if(_index == index) {
				dev_info = (String) devinfo.get(str);
				break;
			}
			_index++;
		}
		println(dev_info);
		String sdata = "";
		for (int j=0; j<dev_info.length()/2; j++) {
			data[j] = (int) (0xff & Integer.parseInt(dev_info.substring(j*2, j*2+2),16));

		}
		switch(data[0]) {
		case DEVICE_ID_S10:
			inByte[7] = 0x09;
			
			inByte[10] = 0xF0;
			inByte[11] = 0x09;
			inByte[12] = DEVICE_ID_S10;
			inByte[13] = 0x00;
			inByte[14] = 0x01;
			inByte[15] = 0xFC;
			inByte[16] = 0xFC;
			inByte[17] = 0x01;
			inByte[18] = 0xB3;
			for (int j=0; j<10; j++) {
				inByte[21+j] = data[1+j];
			}
			inByte[31] = add_check_sum(1,inByte);
			break;
		case DEVICE_ID_S11:
			inByte[7] = 0x09;
			
			inByte[10] = 0xF0;
			inByte[11] = 0x09;
			inByte[12] = DEVICE_ID_S11;
			inByte[13] = 0x00;
			inByte[14] = 0x02;
			inByte[15] = 0x78;
			inByte[16] = 0x78;
			inByte[17] = 0x01;
			inByte[18] = 0xAD;
			for (int j=0; j<10; j++) {
				inByte[21+j] = data[1+j];
			}
			inByte[31] = add_check_sum(1,inByte);
			break;
		case DEVICE_ID_S12:
			inByte[7] = 0x0A;
			
			inByte[10] = 0xF0;
			inByte[11] = 0x0A;
			inByte[12] = DEVICE_ID_S12;
			inByte[13] = 0x00;
			inByte[14] = 0x02;
			inByte[15] = 0x02;
			inByte[16] = 0x02;
			inByte[17] = 0x02;
			inByte[18] = 0x01;
			inByte[19] = 0xC5;
			for (int j=0; j<10; j++) {
				inByte[21+j] = data[1+j];
			}
			inByte[31] = add_check_sum(1,inByte);
			break;
		case DEVICE_ID_S13:
			break;
		default:
			break;
		}
		myPort.clear(); 
		
		// for (int j=0; j<32; j++) {
			// print(hex(inByte[j],2),' ');
		// }
			
		for (int i=0; i<32; i++) {
			myPort.write(char(inByte[i]));
		}
		
	}
	
	public void sendAllTestCMD () {
		Enumeration devname;
		devname = devinfo.keys();
		int idevid = 0;
		int i = 0;
		while(devname.hasMoreElements()) {
			String str;
			String str_id;
			str = (String) devname.nextElement();
			str_id = (String) devinfo.get(str);
			
			idevid= (int) (0xff & Integer.parseInt(str_id.substring(0, 2),16));
			if (idevid < 0xC0) {

			} else {
				sendTestCMD(i);
				delay(100);
			}
			i++;
		}
	}
    
}


 /**
 * @函数：void controlEvent(ControlEvent theEvent)
 */
void controlEvent(ControlEvent theEvent) {

  if (theEvent.isController()) {
    if (COM_List == theEvent.getController()) {
      println("Select port : " + int(theEvent.getController().getValue()));
      config_serial_port(int(theEvent.getController().getValue()));
    }
  }
}

 /**
 * @函数：void config_serial_port(int index)
 */
void config_serial_port(int index) {
  println("config serial port");
  // myPort = new Serial( this, Serial.list()[index], 115200);
  myPort = new Serial( this, Serial.list()[index], 9600);
  myPort.clear();
  InitDone = true;

  thread("thread_Serial");
}

byte add_check_sum(int flag, int[] data) {
	int result = 0;
	if (flag == 1) { // 增加sum
		for (int i=0; i<data[2]-1; i++) {
			result += data[i];
		}
		result &=0xFF;
		return (byte)result;
	} else {
		
	}
	return (byte)result;
}

/* 处理串口过来的数据 */
void thread_Serial() {
    while(true) {
    int[] data;
	int idevid = 0;
	String sdev_name = "";
	String sdev_id = "";
        // println("Thread Serial function");
    if (Data_Recived_Flag) {
      data = (int[]) serialInArray.clone();
	  
	  println("Recive one frame data:");
      Data_Recived_Flag = false;
      for (int i=0; i<data[2]; i++) {
      print(hex(data[i],2),' ');
      }
	  println("");
	  
	  if ((data[6] == 0x04 || data[6] == 0x03) && data[8] == 0xFD) {
		  if(data[10] == 0xFF) {
			  led_color = color(0,255,0);
		  } else if (data[10] == 0x00) {
			  led_color = color(255,0,0);
		  }
	  }
	  
	  if(data[8] == 0x20) {
		  if(data[10] == 0xFD) {
			  idevid = data[12];
		  }
	  } else if (data[8] > 0xCF){
		  
	  } else {
		  idevid = data[8];
	  }
	  if(idevid<0x10) {
		sdev_id+='0';
	  }
	  sdev_id = Integer.toHexString(idevid);
	  
	  switch (idevid) {
	  case DEVICE_ID_S01://DEVICE_ID_S10:
		sdev_name = "S01-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	 	  
	  case DEVICE_ID_S02://DEVICE_ID_S10:
		sdev_name = "S02-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S03://DEVICE_ID_S10:
		sdev_name = "S03-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S04://DEVICE_ID_S10:
		sdev_name = "S04-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S05://DEVICE_ID_S10:
		sdev_name = "S05-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S06://DEVICE_ID_S10:
		sdev_name = "S06-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S07://DEVICE_ID_S10:
		sdev_name = "S07-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S08://DEVICE_ID_S10:
		sdev_name = "S08-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;	  
	  case DEVICE_ID_S10://DEVICE_ID_S10:
		sdev_name = "S10-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;
	  case DEVICE_ID_S11://DEVICE_ID_S11:
	    sdev_name = "S11-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;
	  case DEVICE_ID_S12://DEVICE_ID_S12:
	    sdev_name = "S12-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;
	  case DEVICE_ID_S13://DEVICE_ID_S13:
	    sdev_name = "S13-" + Integer.toHexString(data[21]) + Integer.toHexString(data[22]);
		break;
	  default:	
		idevid = 0x00;
		break;
	  }
	  
	  if (idevid == 0x00) {
		  
	  } else {
			for(int i=0;i<10;i++) {
				if(data[21+i]<0x10) {
					sdev_id+='0';
				}
				sdev_id += Integer.toHexString(data[21+i]);
			}
			if(Device.ifrepeat(sdev_name) == 0) {
				Device.createItems(sdev_name,sdev_id);
				UpdateDrawFlag = true;
			}
	  }
    }
        delay(10);
    }
}

void serialEvent(Serial myPort) {
  // read a byte from the serial port:
  
  int inByte = myPort.read();
    // myPort.write(char(inByte));
  if (firstContact == false) {
    if (inByte == 0x55) { 
    serialInArray[0] = inByte;
    firstContact = true;     // you've had first contact from the microcontroller
       // println("I have recived the frame head");
    }
      // myPort.write('A');       // ask for more
  } 
  else {
  serialInArray[serialCount+1] = inByte;
  if (serialInArray[1] == 0x3A) {
    serialCount++;
    if (serialCount >30 ) {
      // println("I have recived the one frame");
      serialCount = 0;
      Data_Recived_Flag = true;
      firstContact = false;
	  myPort.clear(); 
    }
    
  } else {
    firstContact = false;
    serialCount = 0;
	myPort.clear(); 
  }
  }
}

// When a button has been clicked give information aout the 
// button

void handleButtonEvents(GImageButton button, GEvent event) {
	if(InitDone) {
		if (button == btnAllowNet) {
			println("Send allow ZigBee Net Cmd");
			int[] inByte = {0x55, 0x3A, 0x20, 0x00, 0x01, 0x00, 0x02, 0x01, 0xFD, 0x02, 0xFF,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEC};
			for (int i=0; i<inByte.length; i++) {
			  myPort.write(char(inByte[i]));
			}
		
		} else if (button == btnForbitNet) {
			println("Send don't allow ZigBee Net Cmd");
			led_color = color(255,0,0);
			int[] inByte = {0x55, 0x3A, 0x20, 0x00, 0x01, 0x00, 0x02, 0x01, 0xFD, 0x02, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xED};
			for (int i=0; i<inByte.length; i++) {
			  myPort.write(char(inByte[i]));
			}
		} else if (button == btnResetNet) {
			println("Send Reset ZigBee Net Cmd");
			int[] inByte = {0x55, 0x3a, 0x20, 0x01, 0x01, 0x00, 0x02, 0x01, 0xfc, 0x03, 0xff, 
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xed};
			for (int i=0; i<inByte.length; i++) {
			  myPort.write(char(inByte[i]));
			}
			Device.clearDisplay();
			Device.clearItems();
		} else if (button == btnTestAll) {
			println("Send test All Cmd");
			Device.sendAllTestCMD();
		}
	} else {
		println("Please select COM PORT");
	}
}

void customize(DropdownList ddl, ArrayList<String> list) {
  // a convenience function to customize a DropdownList
  ddl.clear();
  ddl.setBackgroundColor(color(255));
  ddl.setItemHeight(25);
  ddl.setBarHeight(25);
  for (int i=0;i<list.size();i++) {
    ddl.addItem(list.get(i), null);
  }
  ddl.setColorBackground(color(100));
  ddl.setColorActive(color(255, 128));
}



/*
This is used for scan serial ports
*/

void scan_serial_ports() {

  ArrayList<String> port_list = new ArrayList<String>();
  String[]  temp_list = {};

  temp_list = Serial.list();
  now_length = temp_list.length;

  if( 0 == now_length ) {
	  COM_List.clear();
	  COM_List.setBackgroundColor(color(255));
	  COM_List.setItemHeight(30);
	  COM_List.setBarHeight(25);
	  // COM_List.addItem("No Port", null);
	  COM_List.setColorBackground(color(100));
	  COM_List.setColorActive(color(255, 128));
    return;
  } else {
	  if (last_length != now_length) {
		  for (int i = 0; i < temp_list.length; i++) {
			if (temp_list[i].contains("/dev/cu") || temp_list[i].contains("COM")) {
			  port_list.add(temp_list[i]);
			}
		  }
		  //printArray(port_list);
		  customize(COM_List, port_list);
	  }
  }
  last_length = now_length;
  
}




public void button_0(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_1(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_2(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_3(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_4(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_5(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_6(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_7(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_8(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_9(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_10(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_11(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_12(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_13(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_14(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_15(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_16(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_17(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_18(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_19(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
public void button_20(int theValue) {
  println("Send TEST CMD : "+theValue);
  Device.sendTestCMD(theValue);
}
