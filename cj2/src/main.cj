package cj2

import std.collection.*
import std.io.*
import std.console.*
import std.convert.*

struct Edge{
    var start:UInt16
    var end:UInt16
    var symbol:Rune

    public init(start: UInt16, end: UInt16, symbol: Rune) {
        this.start = start
        this.end = end
        this.symbol = symbol
    }
    
}


struct Node{
    var start:UInt16
    var end:UInt16                 //NFA
    var edges:ArrayList<Edge> 
    var ends=ArrayList<UInt16>()    //DFA
    public init(start: UInt16, end: UInt16) {
        this.start = start
        this.end = end
        this.edges = ArrayList<Edge>()

    }
    public init(start: UInt16, end: UInt16, edge: Edge) {
        this.start = start
        this.end = end
        this.edges = ArrayList<Edge>(edge)

    }

}

struct Stack<T>{
    private var stack:ArrayList<T>
    public init(){
        stack=ArrayList<T>()
    }
    public init(stack: ArrayList<T>){
        this.stack=stack
    }
    public func size():Int{
        return stack.size
    }
    public func push(item:T){
        stack.append(item)
    }
    public func pop():T{
        return stack.remove(stack.size-1)
    }
    public func isEmpty():Bool{
        return stack.isEmpty()
    }
    public func top():T{
        return stack[stack.size-1]
    }
}

struct Queue<T>{
    private var queue:ArrayList<T>
    public init(){
        queue=ArrayList<T>()
    }
    public init(queue: ArrayList<T>){
        this.queue=queue
    }
    public func size():Int{
        return queue.size
    }
    public func push(item:T){
        queue.append(item)
    }
    public func pop():T{
        return queue.remove(0)
    }
    public func isEmpty():Bool{
        return queue.isEmpty()
    }
    public func front():T{
        return queue[0]
    }
    public func clone():Queue<T>{
        return Queue<T>(queue.clone())
    }
    public func clear(){
        queue.clear()
    }
} 

extend ArrayList<Edge>{
    public operator func +(right:ArrayList<Edge>):ArrayList<Edge>{
        var result=ArrayList<Edge>(this)
        for(i in 0..right.size){
            result.append(right[i])
        }
        return result
    }
} 

open class NFA{
    private let isp = HashMap<Rune,Int>([(r'+',5), (r'|',3), (r'*',7), (r'(', 1), (r')', 8), (r'#', 0)])//栈顶操作符优先级
	private let icp = HashMap<Rune,Int>([(r'+',4), (r'|',2), (r'*',6), (r'(', 8), (r')', 1), (r'#', 0)])//当前操作符优先级
    private var counter:UInt16 = 0
    public var node=Node(0,0)
    private var string:Array<Rune>
    public var letters=HashSet<Rune>()
    public init(string:Array<Rune>){
        this.string=string
    }

    private func is_letter(letter:Rune):Bool{
        return letter!= r'*' && letter!= r'(' && letter!= r')' && letter!= r'|'&&letter!=r'#'&&letter!=r'+'
    }

    private func Preprocess(){
        var string=ArrayList<Rune>()
        
        for (i in 0..this.string.size-1)
        {
            string.append(this.string[i])
            //要加的可能性如ab 、 *b 、 a( 、 )b 等情况
            //若第二个是字母、第一个不是'('、'|'都要添加
            if (this.string[i] != r'(' && this.string[i] != r'|' && is_letter(this.string[i+1]))
            {
                string.append(r'+')
            }
            //若第二个是'(',第一个不是'|'、'(',也要加
            else if (this.string[i+1] == r'(' && this.string[i] != r'|' && this.string[i] != r'(')
            {
                string.append(r'+')
            }
        }
        //将最后一个字符写入
        string.append(this.string[this.string.size-1])
        string.append(r'#')
        this.string=string.toArray()

    }

    private func Concatenation(a:Node,b:Node):Node{
        var node=Node(a.start,b.end)
        node.edges=a.edges+b.edges
        node.edges.append(Edge(a.end,b.start,r' '))
        return node
    }

    private func Union(a:Node,b:Node):Node{
        var node=Node(counter,counter+1)
        node.edges=a.edges+b.edges
        node.edges.append(Edge(counter,a.start,r' '))
        node.edges.append(Edge(counter,b.start,r' '))
        node.edges.append(Edge(a.end,counter+1,r' '))
        node.edges.append(Edge(b.end,counter+1,r' '))
        return node
    }

    private func KleeneStar(a:Node):Node{
        var node=Node(counter,counter+1)
        node.edges+=a.edges
        node.edges.append(Edge(counter,a.start,r' '))
        node.edges.append(Edge(counter,counter+1,r' '))
        node.edges.append(Edge(a.end,counter+1,r' '))
        node.edges.append(Edge(a.end,a.start,r' '))
        return node
    }

    private func eval(stackl:Stack<Node>,stacko:Stack<Rune>){
        let op = stacko.pop()
        let x:Node
        if(op == r'*') {
            let a = stackl.pop()
            x = KleeneStar(a)
            counter+=2
            stackl.push(x)
            return
        }
        let b = stackl.pop()
        let a = stackl.pop()
        if(op == r'+') {x = Concatenation(a,b)}
        else {
            x = Union(a,b)
            counter+=2
        }
        stackl.push(x)
    }

    public func GetNFA(){
        Preprocess()
        var stackl=Stack<Node>()
        var stacko=Stack<Rune>()
        var i=0
        stacko.push(r'#')
        while(i<string.size){
            
            if(is_letter(string[i])){
                stackl.push(Node(counter,counter+1,Edge(counter,counter+1,string[i])))
                if(string[i]!= r' '){
                    letters.put(string[i])
                }
                counter+=2
                i+=1
                continue
            }
            if(isp[stacko.top()]<icp[string[i]]){//栈顶操作符优先级低于当前操作符优先级
                stacko.push(string[i])
                i+=1
                continue
            }

            if(isp[stacko.top()]>icp[string[i]]){//栈顶操作符优先级高于当前操作符优先级
                eval(stackl,stacko)
                continue
            }
            if (stacko.top() == r'#' && string[i] == r'#') { // 遇到两个 #，表达式结束
				break
			}
            stacko.pop()
            i+=1
        }
        this.node=stackl.pop()
    }

    public func Traverse(){
        println("NFA:")
        println("start:${node.start}")
        println("end:${node.end}")
        for(i in node.edges){
            println("${i.start}->${i.symbol}->${i.end}")
        }
    }


    public func Test(s:String){
        let string=s.toRuneArray()
        var flag=false
        func DFS(i:Int,start:UInt16):Unit{
            if(start==node.end){
                flag=true
                return
            }
            for(j in node.edges where j.start==start){
                if(j.symbol==r' '){
                    DFS(i,j.end)
                }
                if(i<string.size){
                    if(j.symbol==string[i]){
                        DFS(i+1,j.end)
                    }
                }
                if(flag){
                    return
                }
            }
        }
        DFS(0,node.start)
        if(flag){
            println("true")
            return
        }
        println("false")
    }

}

class DFA<:NFA{
    public DFA(string:Array<Rune>){
        super(string)
    }
    var node_DFA=Node(0,0)

    private var Dstates_temp=ArrayList<UInt16>()
    private var Dstates=ArrayList<ArrayList<UInt16>>()
    private var Dtrans=ArrayList<(UInt16,Rune,UInt16)>()
    
    private func DFS(start:UInt16,symbol:Rune):Unit{
        if(!Dstates_temp.contains(start)){
            Dstates_temp.append(start)
        }
        for(i in node.edges){
            if(i.start==start&&i.symbol==symbol){
                if(!Dstates_temp.contains(i.end)){
                    Dstates_temp.append(i.end)
                    DFS(i.end,symbol)
                }
            }
        }
    }

    private func closure(start:UInt16):ArrayList<UInt16>{
        this.Dstates_temp.clear()
        DFS(start,r' ')
        return this.Dstates_temp
    }

    private func closure(Dstates:ArrayList<UInt16>):ArrayList<UInt16>{
        var Dstates_temp=Dstates.clone()
        for(i in Dstates){
            let temp=closure(i)
            for(j in temp){
                if(!Dstates_temp.contains(j)){
                    Dstates_temp.append(j)
                }
            }
        }
        return Dstates_temp
    }

    private func edge(start:UInt16,symbol:Rune):ArrayList<UInt16>{
        var Dstates_temp=ArrayList<UInt16>()
        for(i in node.edges){
            if(i.start==start&&i.symbol==symbol){
                if(!Dstates_temp.contains(i.end)){
                    Dstates_temp.append(i.end)
                }
                
            }
        }
        return Dstates_temp
    }

    private func edge(Dstates:ArrayList<UInt16>,symbol:Rune):ArrayList<UInt16>{
        var Dstates_temp=ArrayList<UInt16>()
        for(i in Dstates){
            let temp=edge(i,symbol)
            for(j in temp){
                if(!Dstates_temp.contains(j)){
                    Dstates_temp.append(j)
                }
            }
        }
        return Dstates_temp
    }

    private func DFA_edge(Dstates:ArrayList<UInt16>,symbol:Rune):ArrayList<UInt16>{
        var Dstates_temp=ArrayList<UInt16>()
        Dstates_temp=closure(edge(Dstates,symbol))
        return Dstates_temp
    }

    public func NFAtoDFA(){
        var Dstates=ArrayList<ArrayList<UInt16>>()
        Dstates.append(closure(node.start).clone())
        var p=1
        var j=1 
        while(j<=p){   
            for(letter in letters){
                var flag=false
                var e=DFA_edge(Dstates[j-1],letter)
                if(e.isEmpty()){continue}
                for(i in 0..Dstates.size){
                    if(Dstates[i]==e){
                        Dtrans.append((UInt16(j-1),letter,UInt16(i)))
                        flag=true
                        break
                    }
                }
                if(!flag){
                    p+=1
                    Dstates.append(e)
                    Dtrans.append((UInt16(j-1),letter,UInt16(p-1)))
                }
            }
            j+=1
        }

        for(i in 0..Dstates.size){
            if(Dstates[i].contains(node.end)){
                node_DFA.ends.append(UInt16(i))
            }
            for(j in 0..Dtrans.size){
                if(Dtrans[j][0]==UInt16(i)){
                    node_DFA.edges.append(Edge(Dtrans[j][0],Dtrans[j][2],Dtrans[j][1]))
                }
            }
        }
        this.Dstates=Dstates
    }
    
    private func samebelongto(set:ArrayList<ArrayList<UInt16>>,a:UInt16,b:UInt16):Bool{
        for(arr in set){
            if(arr.contains(a)&&arr.contains(b)){
                return true
            }
        }
        return false
    }

    private func spiltset(set:ArrayList<ArrayList<UInt16>>,a:ArrayList<UInt16>){
        for(arr in set where arr.contains(a[0])){
            for(item in a){
                arr.removeIf({i=>i==item})
            }
        }
        set.append(a)
    }

    
    public func MinimizeDFA(traverse!:Bool=true){
        var Dstates_origin=Queue<Array<UInt16>>()
        var Dstates_origin_temp=Queue<Array<UInt16>>()
        let D1=node_DFA.ends.clone()
        var D2=ArrayList<UInt16>()
        for(i in 0..Dstates.size){
            if(!D1.contains(UInt16(i))){
                D2.append(UInt16(i))
            }
        }
        var set=ArrayList<ArrayList<UInt16>>()
        Dstates_origin.push(D1.toArray())
        set.append(ArrayList<UInt16>(D1.toArray()))
        if(!D2.isEmpty()){
            Dstates_origin.push(D2.toArray())
            set.append(ArrayList<UInt16>(D2.toArray()))
        }
        
        var i=0
        while(i< letters.size){
            let letter=letters.toArray()[i]
            let set_temp=set.clone()
            while(!Dstates_origin.isEmpty()){
                var D=Dstates_origin.pop()
                if(D.size==1){
                    continue
                }
                var end=Array<UInt16>(D.size,repeat:UInt16(Dstates.size))
                var Dstates_temp=Array<ArrayList<UInt16>>(D.size,{_=>ArrayList<UInt16>()})
                for(i in 0..D.size){
                    for(j in node_DFA.edges where j.start==D[i]){
                        if(j.symbol==letter){
                            end[i]=j.end
                            break
                        }
                    }
                } 
                var flag=Array<Bool>(D.size,repeat:true)
                
                for(i in 0..end.size where flag[i]){
                    for(j in i+1..end.size){
                        if(samebelongto(set,end[i],end[j])){
                            Dstates_temp[i].append(D[j])
                            flag[j]=false
                        }
                    }
                }
        
                for(i in 0..D.size where flag[i]){
                    Dstates_temp[i].insert(0,D[i])
                    if(HashSet<UInt16>(Dstates_temp[i].toArray())==HashSet<UInt16>(D)){
                        Dstates_origin_temp.push(D)
                        break
                    }
                    spiltset(set,Dstates_temp[i])
                    Dstates_origin.push(Dstates_temp[i].toArray().clone())
                    
                }
            }
            Dstates_origin=Dstates_origin_temp.clone()
            Dstates_origin_temp.clear()
            if(set_temp==set){
                i+=1
            }
        } 
        if(Dstates_origin.isEmpty()) {
            println("DFA is already minimal")
            return
        }
        println("After minimize:") 
        while(!Dstates_origin.isEmpty()){
            let D=Dstates_origin.pop()
            for(i in 1..D.size){
                if(node.start==D[i]){
                    node_DFA.start=D[0]
                }
                for(j in 0..node_DFA.ends.size where node_DFA.ends[j]==D[i]){
                    node_DFA.ends.remove(j)
                    if(!node_DFA.ends.contains(D[0])){
                        node_DFA.ends.append(D[0])
                    }
                    break
                }
                var j=0
                while(j <node_DFA.edges.size){
                    if(node_DFA.edges[j].start==D[i]){
                        node_DFA.edges.remove(j)
                        continue
                    }
                    if(node_DFA.edges[j].end==D[i]){
                        var t=node_DFA.edges[j].start
                        if(node_DFA.edges[j].start==D[i]){
                            t=D[0]
                        }
                        node_DFA.edges[j]=Edge(t,D[0],node_DFA.edges[j].symbol)
                        j+=1
                        continue
                    }
                    j+=1
                }
            }
        }
        if(traverse){
            Traverse(isDFA:true)
        }
    }

    public func Traverse(isDFA!:Bool){
        if(!isDFA){
            super.Traverse()
            return
        }
        println("DFA:")
        println("start:${node_DFA.start}")
        println("end:${node_DFA.ends}")
        for(i in node_DFA.edges){
            println("${i.start}->${i.symbol}->${i.end}")
        }
    }

    public func Test(s:String,isDFA!:Bool){
        if(!isDFA){
            super.Test(s)
            return
        }
        let string=s.toRuneArray()
        var flag=false
        func DFS(i:Int,start:UInt16):Unit{
            for(i in node_DFA.ends where i==start){
                flag=true
                return
            }
            if(i==string.size){
                return
            }
            for(j in node_DFA.edges where j.start==start){
                if(j.symbol==string[i]){
                    DFS(i+1,j.end)
                }
                if(flag){
                    return
                }
            }
        }
        DFS(0,node_DFA.start)
        if(flag){
            println("true")
            return
        }
        println("false")
    }

}




main() {
    // while(true){
    //     // println("请输入正则表达式:")
    //     // let c:String=Console.stdIn.readln().getOrThrow()
    //     // let dfa=DFA(c.toRuneArray())
    //     // dfa.GetNFA()        //得到NFA
    //     // dfa.Traverse()      //输出NFA
    //     // while(true){
    //     //     let d:String=Console.stdIn.readln().getOrThrow()
    //     //     if(d=="exit") {break}
    //     //     dfa.Test(d)	//测试NFA是否可以接受字符串
    //     // }
    //     // dfa.NFAtoDFA()      //将NFA转为DFA
    //     // dfa.Traverse(isDFA:true)
    //     // while(true){
    //     //     let d:String=Console.stdIn.readln().getOrThrow()
    //     //     if(d=="exit") {break}
    //     //     dfa.Test(d,isDFA:true)	//测试DFA是否可以接受字符串
    //     // }
    //     // dfa.MinimizeDFA()			//最小化DFA
    //     // while(true){
    //     //     let d:String=Console.stdIn.readln().getOrThrow()
    //     //     if(d=="exit") {break}
    //     //     dfa.Test(d,isDFA:true)	//测试最小化后的DFA是否可以接受字符串
    //     // }

    // } 
    return 0
}
