//
//  ViewController.swift
//  Demo_CoreBluetooth
//
//  Created by yueyeqi on 27/12/2016.
//  Copyright © 2016 yueyeqi. All rights reserved.
//

import UIKit
import CoreBluetooth //导入蓝牙框架

//添加蓝牙代理
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var tableView: UITableView!
    var manager: CBCentralManager?//中心角色
    var per: CBPeripheral?//服务
    var readCharac: CBCharacteristic? // 读取特征
    var writeCharac: CBCharacteristic? // 写入特征
    
    var deviceArray: [CBPeripheral] = [] //外设数据源
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //建立中心角色
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //判断蓝牙是否开启，并开始扫描
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let central = manager {
            switch central.state {
            case .poweredOn:
                print("蓝牙已打开，请扫描外设")
                manager?.scanForPeripherals(withServices: nil, options: nil)
            case .poweredOff:
                print("蓝牙没有打开，请先打开蓝牙")
            default:
                break
            }
        }
    }
    
    //查找外设的代理
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //查找到外设后添加到数据源里面，并刷新tableView数据
        if !deviceArray.contains(peripheral) {
            deviceArray.append(peripheral)
        }
        tableView.reloadData()
    }
    
    //连接外设成功，启动发现服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("连接成功：\(peripheral.name)")//打印外设name
        peripheral.delegate = self
        peripheral.discoverServices(nil)//开始发现服务
        per = peripheral
    }
    
    //连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败：\(peripheral.name)")
    }
    
    //发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //遍历服务，发现服务下的特征
        for server in peripheral.services! {
            //也可以通过服务UUID来过滤服务
            //server.uuid
            peripheral.discoverCharacteristics(nil, for: server)
        }
    }
    
    //信号检测
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let rssi = abs(RSSI .intValue)
        let str = "发现BLT4.0热点：\(peripheral)，强度：\(rssi)"
        print(str)
    }
    
    //搜索到特征Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("服务UUID：\(service.uuid)")
        //遍历每个服务下的特征
        for c in service.characteristics! {
            print("特征UUID:\(c.uuid)")
            //根据外设所定制的特征，分别处理
            //比如特征"1111"为读取，"2222"为写入
            if (c.uuid.uuidString.range(of: "1111") != nil) {
                readCharac = c
                peripheral.readRSSI()//检测外设信号
                peripheral.readValue(for: c)//读取一次特征值
                peripheral.setNotifyValue(true, for: c)//当特征值改变时通知
            }else if (c.uuid.uuidString.range(of: "2222") != nil) {
                //写入的特征
                writeCharac = c
            }
        }
    }
    
    //获取外设发来的数据(无论是读取还是通知，都在这个方法接收)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "1111") {
            let data = characteristic.value
            //data则是读取过来的数据
        }
    }
    
    //检测中心向外设写数据是否成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("发送失败")
        }else {
            print("发送成功")
        }
    }
    
    //模拟写入数据
    //func testWriteData() {
    //    per?.writeValue(writeData, for: writeCharac!, type: CBCharacteristicWriteType.withResponse)
    //}
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identified = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identified)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identified)
        }
        let per = deviceArray[indexPath.row]
        
        if let name = per.name {
            cell?.textLabel?.text = name
        }else {
            cell?.textLabel?.text = per.identifier.uuidString
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        per = deviceArray[indexPath.row]
        manager?.connect(per!, options: nil)
    }
}

